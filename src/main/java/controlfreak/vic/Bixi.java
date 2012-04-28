package controlfreak.vic;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.util.ToolRunner;

public class Bixi 
{
	public static void main(String[] args) throws Exception 
    {
        if (args.length != 2) {
            System.err.println("Usage: " + Bixi.class.getName() + " <input> <output1>");
            System.exit(2);
        }
        
        int result1 = ToolRunner.run(new Configuration(), new BixiHistogram(), args);
        
        System.out.println(result1);
    }
}
