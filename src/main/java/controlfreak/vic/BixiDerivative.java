package controlfreak.vic;

import java.io.IOException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Map;
import java.util.TreeMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.DoubleWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.TextInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.util.Tool;
import org.hackreduce.models.StockExchangeDividend;


public class BixiDerivative extends Configured implements Tool
{
    public enum Count 
    {
    	STATION_DAY_HOURS,
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
    public static class BixiDerivativeMapper extends Mapper<LongWritable, Text, Text, Text>
    {
        private static final Logger LOG = Logger.getLogger(BixiDerivativeMapper.class.getName());
                
		
        public void map(LongWritable key, Text value, Context context)
        {
            try 
            {
                String line = value.toString();
                String[] record = line.split(",");
                
                Calendar cal = Calendar.getInstance();
                java.util.Date time = new java.util.Date(Long.parseLong(record[12])*1000);
                cal.setTime(time);
                
                DateFormat hourDateFormat = new SimpleDateFormat("HH");
                
                String k = record[3] + "," + record[4] + "," + cal.get(Calendar.DAY_OF_YEAR) + "," + hourDateFormat.format(time);
                
                context.write(new Text(k), new Text(record[12] + "-" + record[10]));
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
    public static class BixiDerivativeReducer extends Reducer<Text, Text, Text, Text> 
    {
        // private static NumberFormat currencyFormat = NumberFormat.getCurrencyInstance(Locale.getDefault());
        
        @Override
        protected void reduce(Text key, Iterable<Text> values, Context context) throws IOException, InterruptedException 
        {
            context.getCounter(Count.STATION_DAY_HOURS).increment(1);
            
            Map<Long, Integer> times = new TreeMap<Long, Integer>();
            
            for (Text value : values)
            {
            	String split[] = value.toString().split("-");
            	times.put(Long.parseLong(split[0]), Integer.parseInt(split[1]));
            }
            
            int flux = 0;
            
            if (times.size() > 1)
            {
            	boolean first = true;
            	long prev = -1;
            	
            	int deltas = 0;
            	
            	for (Long timesKey : times.keySet())
                {
                	if (first)
                	{
                		first = false;
                		prev = timesKey;
                	}
                	else
                	{
                		deltas += times.get(timesKey) - times.get(prev);
                	}
                }
            	
            	flux = deltas / times.size();
            }
            
			context.write(key, new Text(flux + ""));
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
        job.setMapperClass(BixiDerivativeMapper.class);
        job.setReducerClass(BixiDerivativeReducer.class);
        
        // This is what the Mapper will be outputting to the Reducer
        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);

        // This is what the Reducer will be outputting
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        job.setInputFormatClass(TextInputFormat.class);
        job.setOutputFormatClass(TextOutputFormat.class);
        
        // Setting the input folder of the job 
        FileInputFormat.addInputPath(job, new Path(args[0]));

        // Preparing the output folder by first deleting it if it exists
        Path output = new Path(args[1]);
        FileSystem.get(conf).delete(output, true);
        FileOutputFormat.setOutputPath(job, output);

        return job.waitForCompletion(true) ? 0 : 1;
    }
        
}
