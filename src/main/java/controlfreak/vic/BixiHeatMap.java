package controlfreak.vic;

import java.io.IOException;
import java.util.Map;
import java.util.TreeMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.KeyValueTextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.util.Tool;


public class BixiHeatMap extends Configured implements Tool
{
    public enum Count 
    {
    	STATIONS,
        RECORDS_SKIPPED,
        RECORDS_MAPPED
    }

    /*
     * K, V, K1, V1
     * The key value pair received by the mapper (K, V) depends on the InputFormat implementation used
     * Regular TextInputFormat is LongWritable, Text
     * 
     * K1, V1 is implementation dependent
     * here we are mapping stock symbol to the dividends
     */
    public static class BixiHeatMapMapper extends Mapper<Text, Text, Text, Text>
    {
        private static final Logger LOG = Logger.getLogger(BixiHeatMapMapper.class.getName());
                
		
        public void map(Text key, Text value, Context context)
        {
            try 
            {
                String components[] = key.toString().split("\\|");
            	String averageBikes = value.toString();
                
                String k = components[0] + "," + components[1];
                String v = components[2] + "-" + averageBikes;
                // LOG.warning(k + " : " + v);
                
                context.write(new Text(k), new Text(v));
            } 
            catch (Exception e) 
            {
                LOG.log(Level.WARNING, e.getMessage() + "\n" + value.toString(), e);
                context.getCounter(Count.RECORDS_SKIPPED).increment(1);
                return;
            }
            
            context.getCounter(Count.RECORDS_MAPPED).increment(1);
        }
    }
    
    
    /*
     * K1, V1, K2, V2
     * K1, V1 is the output of map
     * K2, V2 is the result of the reduction
     * 
     */    
    public static class BixiHeatMapReducer extends Reducer<Text, Text, Text, Text> 
    {
    	private static final Logger LOG = Logger.getLogger(BixiHeatMapReducer.class.getName());
    	
        // private static NumberFormat currencyFormat = NumberFormat.getCurrencyInstance(Locale.getDefault());
        
        @Override
        protected void reduce(Text key, Iterable<Text> values, Context context) throws IOException, InterruptedException 
        {
            context.getCounter(Count.STATIONS).increment(1);

            Map<Integer, Integer> times = new TreeMap<Integer, Integer>();
            
            int count = 0;
            
            for (Text value : values)
            {
            	++count;
            	String split[] = value.toString().split("-");
            	times.put(Integer.parseInt(split[0]), Integer.parseInt(split[1]));
            }
            
            String deltas = "";
            
            for (int i = 0; i < count; ++i)
            {
            	int delta = 0;
            	
            	if (times.size() > 1)
            	{
            		if (i == 0)
                	{
                		delta = times.get(i) - times.get(times.size() - 1);
                	}
                	else
                	{
                		delta = times.get(i) - times.get(i - 1);
                	}
            	}
            	
            	deltas += delta + ",";
            }
            
            context.write(key, new Text(deltas.substring(0, deltas.length() - 1)));
            
        }
    }
    
    
    @Override
    public int run(String[] args) throws Exception 
    {
        Configuration conf = getConf();
        
        // Creating the MapReduce job (configuration) object
        Job job = new Job(conf);
        job.setJarByClass(getClass());
        job.setJobName(getClass().getName());

        // Tell the job which Mapper and Reducer to use (classes defined above)
        job.setMapperClass(BixiHeatMapMapper.class);
        job.setReducerClass(BixiHeatMapReducer.class);
        
        // This is what the Mapper will be outputting to the Reducer
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);

        // This is what the Reducer will be outputting
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        job.setInputFormatClass(KeyValueTextInputFormat.class);
        job.setOutputFormatClass(TextOutputFormat.class);
        
        // Setting the input folder of the job 
        FileInputFormat.addInputPath(job, new Path(args[1]));

        // Preparing the output folder by first deleting it if it exists
        Path output = new Path(args[2]);
        FileSystem.get(conf).delete(output, true);
        FileOutputFormat.setOutputPath(job, output);

        return job.waitForCompletion(true) ? 0 : 1;
    }
        
}
