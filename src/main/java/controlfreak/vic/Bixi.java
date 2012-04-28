package controlfreak.vic;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.util.ToolRunner;

public class Bixi 
{
	public static void main(String[] args) throws Exception 
    {
		/*
		if (args.length != 3) {
            System.err.println("Usage: " + Bixi.class.getName() + " <input> <output1> <output2>");
            System.exit(2);
        }
        */
		
		if (args.length != 2) {
            System.err.println("Usage: " + Bixi.class.getName() + " <input> <output1>");
            System.exit(2);
        }
		
        int result1 = ToolRunner.run(new Configuration(), new BixiDerivative(), args);
        // int result2 = ToolRunner.run(new Configuration(), new BixiHeatMap(), args);
        
        // System.out.println(result1 + " " + result2);
    }
}
