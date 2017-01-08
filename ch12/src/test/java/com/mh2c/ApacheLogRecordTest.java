/*
Copyright 2017 William A. Havanki, Jr.

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

import static org.junit.Assert.assertEquals;

import java.time.ZonedDateTime;
import java.time.temporal.ChronoUnit;

import org.junit.Before;
import org.junit.Test;

public class ApacheLogRecordTest {

  private ZonedDateTime now;
  private ApacheLogRecord record;

  @Before
  public void setUp() {
    now = ZonedDateTime.now().truncatedTo(ChronoUnit.SECONDS);
    record = new ApacheLogRecord("203.0.113.101", now, "GET", "/index.html", 200, 123L,
                                 "MyBrowser");
  }

  @Test
  public void testParsing() {
    String logLine =
      "203.0.113.101 - - [" + ApacheLogRecord.TIMESTAMP_FORMATTER.format(now) +
      "] \"GET /index.html HTTP/1.0\" 200 123 \"http://example.com\" \"MyBrowser\"";

    record = new ApacheLogRecord(logLine);
    assertEquals("203.0.113.101", record.getIpAddress());
    assertEquals(now.toInstant(), record.getDateTime().toInstant());
    assertEquals("GET", record.getMethod());
    assertEquals("/index.html", record.getResource());
    assertEquals(200, record.getStatus());
    assertEquals(123L, record.getBytes());
    assertEquals("MyBrowser", record.getUserAgent());
  }

  @Test
  public void testWithIpAddress() {
    record = record.withIpAddress("203.0.113.102");
    assertEquals("203.0.113.102", record.getIpAddress());
  }

  @Test
  public void testWithUserAgent() {
    record = record.withUserAgent("Opera");
    assertEquals("Opera", record.getUserAgent());
  }
}
