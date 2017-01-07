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

package com.mh2c;

import java.io.IOException;
import java.io.StringReader;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapred.JobConf;
import org.apache.hadoop.mapred.Mapper;
import org.apache.hadoop.mapred.MapReduceBase;
import org.apache.hadoop.mapred.OutputCollector;
import org.apache.hadoop.mapred.Reporter;
import org.w3c.dom.Document;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

/**
 * Mapper that parses the XML for a Wikipedia article and emits the article's
 * title and text content.
 */
public class WikipediaDumpLoaderMapper extends MapReduceBase
  implements Mapper<Text, Text, Text, Text> {

  private enum Counter { ARTICLES }

  private DocumentBuilder db;

  @Override
  public void configure(JobConf conf) {
    try {
      db = DocumentBuilderFactory.newInstance().newDocumentBuilder();
    } catch (ParserConfigurationException e) {
      throw new IllegalStateException("XML parser configuration is bad", e);
    }
  }

  /**
   * key = article content
   * value = empty string
   */
  @Override
  public void map(Text key, Text value, OutputCollector<Text, Text> output,
                  Reporter reporter) throws IOException {
    try {
      // Parse the page of XML into a document
      Document doc = db.parse(new InputSource(new StringReader(key.toString())));

      // Extract the title and text (article content) from the page content
      String title = doc.getElementsByTagName("title").item(0).getTextContent();
      String text = doc.getElementsByTagName("text").item(0).getTextContent();

      // Emit the title and text pair
      output.collect(new Text(title), new Text(text));
      reporter.getCounter(Counter.ARTICLES).increment(1L);
    } catch (SAXException e) {
      throw new IOException(e);
    }
  }
}
