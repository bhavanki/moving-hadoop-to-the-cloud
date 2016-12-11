/*
Copyright 2016 William A. Havanki, Jr.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package com.dahitc;

import java.io.IOException;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.Mapper;
import org.apache.hadoop.mapred.MapReduceBase;
import org.apache.hadoop.mapred.OutputCollector;
import org.apache.hadoop.mapred.Reporter;

/**
 * Mapper that takes in Wikipedia article text and counts the words in it.
 */
public class WikipediaWordCountMapper extends MapReduceBase
  implements Mapper<Text, Text, Text, IntWritable> {

  private static final IntWritable ONE = new IntWritable(1);
  private Text wordText = new Text();

  /**
   * key = title
   * value = text
   */
  @Override
  public void map(Text key, Text value, OutputCollector<Text, IntWritable> output,
                  Reporter reporter) throws IOException {
    // Split the text content of the article on whitespace
    String[] words = value.toString().split("\\s+");
    // Count each word occurrence
    for (String word : words) {
      wordText.set(word);
      output.collect(wordText, ONE);
    }
  }
}
