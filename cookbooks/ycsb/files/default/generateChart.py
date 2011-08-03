#!/usr/bin/env python

# columns = ["Type", "Elapsed Time (seconds)", "Operations", "Ops/Sec", "Average Latency"]

import sys

if len(sys.argv) > 1:
  filename = sys.argv[1]
else:
  print "Usage: generateChart.py <input-filename>"
  print "Produces: <input-filename>.html"
  print
  sys.exit()

opsCols = ["Elapsed Time (seconds)", "Ops/Sec"]
opsColsString = ""
for heading in opsCols:
    opsColsString += "      opsData.addColumn('number', '" + heading + "');\n"

latencyCols = ["Elapsed Time (seconds)", "Average Latency"]
latencyColsString = ""
for heading in latencyCols:
    latencyColsString += "      latencyData.addColumn('number', '" + heading + "');\n"

opsData = ""
latencyData = ""
with open(filename, 'r') as f:
    read_data = f.readlines()
    for line in read_data:
        if "sec" in line and "operations" in line and "current ops/sec" in line:
            line = line.strip().split()
            try:
              dataType = line[7].strip('[')
              dataTime = line[0]
              dataOps = str(int(line[2]))
              dataOpsSec = line[4]
              dataLatency = line[8].strip("]").split("=")[1]
              # dataString += "        ['" + dataType + "', " + dataTime + ", " + dataOps + ", " + dataOpsSec + ", " + dataLatency + "],\n"
              opsData += "        [" + dataTime + ", " + dataOpsSec + "],\n"
              latencyData += "        [" + dataTime + ", " + dataLatency + "],\n"
            except Exception:
              pass

html = """
<html>
  <head>
    <!--Load the AJAX API-->
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
    
    // Load the Visualization API and the piechart package.
    google.load('visualization', '1.0', {'packages':['corechart']});

    // Set a callback to run when the Google Visualization API is loaded.
    google.setOnLoadCallback(drawOps);
    google.setOnLoadCallback(drawLatency);

    function drawOps() {

      // Create the data table.
      var opsData = new google.visualization.DataTable();
""" + opsColsString + """
      opsData.addRows([
""" + opsData[:-2] + """
      ]);

      // Set chart options
      var options = {'title':'Operations per Second',
                     'width':1920,
                     'height':600,
                     'curveType': 'function',
                     'pointSize': 3,
                     'lineWidth': 1
                     };

      // Instantiate and draw our chart, passing in some options.
      var opsChart = new google.visualization.ScatterChart(document.getElementById('chart_ops'));
      opsChart.draw(opsData, options);
    }

    function drawLatency() {

      // Create the data table.
      var latencyData = new google.visualization.DataTable();
""" + latencyColsString + """
      latencyData.addRows([
""" + latencyData[:-2] + """
      ]);

      // Set chart options
      var options = {'title':'Average Latency',
                     'width':1920,
                     'height':600,
                     'curveType': 'function',
                     'pointSize': 3,
                     'lineWidth': 1
                     };

      // Instantiate and draw our chart, passing in some options.
      var latencyChart = new google.visualization.ScatterChart(document.getElementById('chart_latency'));
      latencyChart.draw(latencyData, options);
    }
    </script>
  </head>

  <body>
    <!--Div that will hold the pie chart-->
    <div id="chart_ops"></div>
    <div id="chart_latency"></div>
  </body>
</html>
"""
with open(filename + '.html', 'w') as f:
    f.write(html)

print filename + ".html has been created."
