package com.dahitc;

import java.io.IOException;
import java.util.Iterator;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.Reducer;
import org.apache.hadoop.mapred.MapReduceBase;
import org.apache.hadoop.mapred.OutputCollector;
import org.apache.hadoop.mapred.Reporter;

/**
 * Reducer that sums up word counts.
 */
public class WikipediaWordCountReducer extends MapReduceBase
  implements Reducer<Text, IntWritable, Text, IntWritable> {

  private IntWritable sumIntWritable = new IntWritable();

  /**
   * key = word
   * values = counts
   */
  @Override
  public void reduce(Text key, Iterator<IntWritable> values,
                     OutputCollector<Text, IntWritable> output, Reporter reporter)
    throws IOException {

    // Total up the incoming counts for the word
    int sum = 0;
    while (values.hasNext()) {
      sum += values.next().get();
    }
    // Emit the word count
    sumIntWritable.set(sum);
    output.collect(key, sumIntWritable);
  }
}
