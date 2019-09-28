import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as log;

void main() => runApp(NocturnalApp());

class _NocturnalApp extends State<NocturnalApp> {
  Brightness brightness = Brightness.light;

  void updateAwake(bool a)
  {
    setState(() {
      brightness = a ? Brightness.light : Brightness.dark; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nocturnal',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: brightness
      ),
      home: Nocturnal(title: 'Nocturnal'),
    );
  }
}

class NocturnalApp extends StatefulWidget {
  static _NocturnalApp of(BuildContext context) => context.ancestorStateOfType(const TypeMatcher<_NocturnalApp>());
  NocturnalApp({Key key}) : super(key: key);

  @override
  _NocturnalApp createState() => _NocturnalApp();
}

class Nocturnal extends StatefulWidget {
  Nocturnal({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _Nocturnal createState() => _Nocturnal();
}

class _Nocturnal extends State<Nocturnal> {
  bool awake = true;
  NocturnalEvents events = new NocturnalEvents();
  int avgCycleLength3 = 0;
  int avgDayCycleLength3 = 0;
  int avgNightCycleLength3 = 0;
  int avgCycleLength7 = 0;
  int avgDayCycleLength7 = 0;
  int avgNightCycleLength7 = 0;
  int avgCycleLength31 = 0;
  int avgDayCycleLength31 = 0;
  int avgNightCycleLength31 = 0;
  int fullCount = 0;
  int dayCount = 0;
  int nightCount = 0;
  int percentAwake = 0;
  int percentAsleep = 0;
  String wakeTime = "";
  String sleepTime = "";

  _Nocturnal()
  {
    loadData().then((d) => events = d)
    .then((x) => loadAwake()
    .then((g) => awake = g)
    .then((h) => setState(() {
      log.log(awake ? "Currently Awake" : "Currently Asleep");
      log.log("Entries: " + events.events.length.toString());
      updateCalculations();
    })));
  }
  
  int timeMs()
  {
    return DateTime.now().millisecondsSinceEpoch;
  }

  List<Cycle> getFullCycles(int max)
  {
    int phase = 0;
    int a = 0;
    int c = 0;
    List<Cycle> cycles = new List<Cycle>();

    for(int i = events.events.length - 1; i > 0; i--)
    {
      NocturnalEvent e = events.events[i];

      if(phase == 0 && e.action == NocturnalAction.WAKING_UP)
      {
        phase++;
        c = e.ms;
      }

      else if(phase == 1 && e.action == NocturnalAction.GOING_TO_SLEEP && c > 0)
      {
        phase++;
      }

      else if(phase == 2 && e.action == NocturnalAction.WAKING_UP && c > 0)
      {
        phase = 0;
        a = e.ms;
        cycles.add(new Cycle(a, c));
      }

      if(cycles.length >= max)
      {
        break;
      }
    }

    return cycles;
  }

  List<Cycle> getHalfCycles(int max, NocturnalAction side)
  {
    bool enter = false;
    int start = 0;
    int end = 0;
    List<Cycle> cycles = new List<Cycle>();

    for(int i = events.events.length - 1; i > 0; i--)
    {
      NocturnalEvent e = events.events[i];

      if(!enter && e.action != side)
      {
        enter = true;
        end = e.ms;
      }

      else if(enter && e.action == side && end > 0)
      {
        enter = false;
        start = e.ms;
        cycles.add(new Cycle(start, end));
      }

      if(cycles.length >= max)
      {
        break;
      }
    }

    return cycles;
  } 
  
  int computeAverageFullCycleTime(int maxCycles)
  {
    double avg = 0;
    int itr = 0;

    getFullCycles(maxCycles).forEach((c) {
      avg += c.getDuration();
      itr++;
    });

    if(itr < maxCycles)
    {
      return -1;
    }

  log.log("Hm" + (avg / itr).round().toString());

    return (avg / itr).round();
  }

  int computeAverageHalfCycleTime(int maxCycles, NocturnalAction side)
  {
    double avg = 0;
    int itr = 0;

    getHalfCycles(maxCycles, side).forEach((c) {
      avg += c.getDuration();
      itr++;
    });

    if(itr < maxCycles)
    {
      return -1;
    }

    return (avg / itr).round();
  }

  Future<bool> saveAwake(bool value) async
  {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool("awake", value);
  }

  Future<bool> loadAwake() async
  {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool("awake") ?? false;
  }

  Future<NocturnalEvents> loadData() async
  {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    try
    {
      NocturnalEvents e = new NocturnalEvents();
      e.fromString(prefs.getString("events"));
      return e;
    }
    
    catch(e)
    {
      log.log(e.toString());
      log.log("Failed to load Data. Adding empty entries");
      return new NocturnalEvents();
    };
  }

  Future<bool> saveData(NocturnalEvents data) async
  {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    return prefs.setString("events", data.toString());
  }

  void toggleAwake()
  {
    setState(() {
      events.events.add(new NocturnalEvent(timeMs(), awake ? NocturnalAction.GOING_TO_SLEEP : NocturnalAction.WAKING_UP));
      awake = !awake;
    updateCalculations();
    });
    saveData(events).then((v) => log.log((v ? "Saved" : "Failed to save") + " -> " + events.events.length.toString() + " Entries"));
    saveAwake(awake).then((v) => log.log((v ? "Saved" : "Failed to save") + " -> " + (awake ? "Awake" : "Asleep")));
    NocturnalApp.of(context).updateAwake(awake);
  }

  void clearEvents()
  {
    setState(() {
      events.events.clear();
      awake = true;
      updateCalculations();
    });
    saveData(events).then((v) => log.log((v ? "Saved" : "Failed to save") + " -> " + events.events.length.toString() + " Entries"));
    saveAwake(awake).then((v) => log.log((v ? "Saved" : "Failed to save") + " -> " + (awake ? "Awake" : "Asleep")));
    NocturnalApp.of(context).updateAwake(awake);
  }

  int computeFullCycleCount()
  {
    return (events.events.length / 2).floor().toInt();
  }

  int computeHalfCycleCount(NocturnalAction side)
  {
    return events.events.length - (events.events.length % 2 == 0 ? 0 : 1);
  }

  String computeTime(int cycles, NocturnalAction a)
  {
    int ams = 0;
    int c = 0;
    int lastms = -1;
    int offsetmsper = 0;
    getHalfCycles(cycles, a).forEach((cycle) {
      DateTime d = DateTime.fromMillisecondsSinceEpoch(cycle.startTime);
      ams += d.minute * 1000 * 60;
      ams += d.hour * 1000 * 60 * 60;
      log.log("Hour is " + d.hour.toString());

      if(lastms > -1)
      {
        offsetmsper += cycle.startTime - lastms;
      }

      lastms = cycle.startTime;
      c++;
    });

    if(c != cycles)
    {
      return "Unknown";
    }

    int hou = 0;
    int min = 0;

    ams = (ams / c).floor().toInt();
    offsetmsper = (offsetmsper / (c - 1)).floor().toInt();
    
    if(ams > 60 * 1000 * 60)
    {
      hou = (ams / (1000 * 60 * 60)).floor();
      ams -= hou * 60 * 60 * 1000;
      min = (ams / (1000 * 60)).ceil();
    }

    if(min == 60)
    {
      min--;
    }
    
    log.log(offsetmsper.toString() + " ms");
    return h12(hou).toString() + ":" + minify(min) + " " + ampm(hou) + (offsetmsper < 0 ? " -" : " +") + durationsh(offsetmsper.abs());
  }

  void updateCalculations()
  {
    fullCount = computeFullCycleCount();
    dayCount = computeHalfCycleCount(NocturnalAction.WAKING_UP);
    nightCount = computeHalfCycleCount(NocturnalAction.GOING_TO_SLEEP);
    avgCycleLength3 = computeAverageFullCycleTime(1); 
    avgDayCycleLength3 = computeAverageHalfCycleTime(3, NocturnalAction.WAKING_UP); 
    avgNightCycleLength3 = computeAverageHalfCycleTime(3, NocturnalAction.GOING_TO_SLEEP); 
    avgCycleLength7 = computeAverageFullCycleTime(3); 
    avgDayCycleLength7 = computeAverageHalfCycleTime(7, NocturnalAction.WAKING_UP); 
    avgNightCycleLength7 = computeAverageHalfCycleTime(7, NocturnalAction.GOING_TO_SLEEP); 
    avgCycleLength31 = computeAverageFullCycleTime(14); 
    avgDayCycleLength31 = computeAverageHalfCycleTime(31, NocturnalAction.WAKING_UP); 
    avgNightCycleLength31 = computeAverageHalfCycleTime(31, NocturnalAction.GOING_TO_SLEEP); 
    
    if(avgNightCycleLength31 > 0 && avgDayCycleLength31 > 0 && avgCycleLength31 > 0)
    {
      percentAwake = ((avgDayCycleLength31 / avgCycleLength31) * 100).round();
      percentAsleep = ((avgNightCycleLength31 / avgCycleLength31) * 100).round();
    }

    else if(avgNightCycleLength7 > 0 && avgDayCycleLength7 > 0 && avgCycleLength7 > 0)
    {
      percentAwake = ((avgDayCycleLength7 / avgCycleLength7) * 100).round();
      percentAsleep = ((avgNightCycleLength7 / avgCycleLength7) * 100).round();
    }

    else if(avgNightCycleLength3 > 0 && avgDayCycleLength3 > 0 && avgCycleLength3 > 0)
    {
      percentAwake = ((avgDayCycleLength3 / avgCycleLength3) * 100).round();
      percentAsleep = ((avgNightCycleLength3 / avgCycleLength3) * 100).round();
    }

    else
    {
      percentAwake = 50;
      percentAsleep = 50;
    }

    wakeTime = computeTime(3, NocturnalAction.WAKING_UP);
    sleepTime = computeTime(3, NocturnalAction.GOING_TO_SLEEP);
  }

  @override
  Widget build(BuildContext context) {
    MaterialColor sw = awake ? Colors.indigo : Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => clearEvents()
          )
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: GridView.count(
          crossAxisCount: 2,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(3),
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text(awake ? "Awake" : "Asleep",
                        style: TextStyle(
                          fontSize: 48,
                          color: awake ? sw.shade700 : sw.shade200
                        ),
                      ),
                    ),
                  ],
                )
              ),
            ),
            TimeCard(
              awake: awake,
              c31: avgCycleLength31,
              c7: avgCycleLength7,
              c3: avgCycleLength3,
              count: fullCount,
              title: "Full Cycle",
              sw: sw,
            ),
            TimeCard(
              awake: awake,
              c31: avgNightCycleLength31,
              c7: avgNightCycleLength7,
              c3: avgNightCycleLength3,
              count: nightCount,
              title: "Night Cycle",
              sw: sw,
            ),
            TimeCard(
              awake: awake,
              c31: avgDayCycleLength31,
              c7: avgDayCycleLength7,
              c3: avgDayCycleLength3,
              count: dayCount,
              title: "Day Cycle",
              sw: sw,
            ),
            PieCard(
              awake: awake,
              percentAwake: percentAwake,
              percentAsleep: percentAsleep,
            ),
            TextCard(
              awake: awake,
              sw: sw,
              title: "Wake Up",
              text: wakeTime,
              title2: "Fall Asleep",
              text2: sleepTime,
            )
          ],
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => toggleAwake(),
        tooltip: 'Sleep',
        backgroundColor: awake ? Colors.indigo : Colors.deepPurple,
        child: Icon(awake ? Nocons.icons8_moon_symbol : Nocons.icons8_sun)
      ),
    );
  }
}

class PieCard extends StatelessWidget
{
  final bool awake;
  final int percentAwake;
  final int percentAsleep;

  PieCard({this.awake, this.percentAwake, this.percentAsleep});

  @override
  Widget build(BuildContext context) {

    return  Padding(
      padding: EdgeInsets.all(3),
      child: Card(
        child: charts.PieChart(
          [
            new charts.Series<NocturnalCycleSegment, int>(
              id: 'Time',
              domainFn: (NocturnalCycleSegment sales, _) => sales.awake,
              measureFn: (NocturnalCycleSegment sales, _) => sales.percentCycle,
              colorFn: (NocturnalCycleSegment sales, _) => sales.color,
              data: [
                new NocturnalCycleSegment(0, percentAwake, charts.ColorUtil.fromDartColor(awake ? Colors.indigo.shade500 : Colors.indigo.shade900.withOpacity(0.5))),
                new NocturnalCycleSegment(1, percentAsleep, charts.ColorUtil.fromDartColor(awake ? Colors.deepPurple.shade100 : Colors.deepPurple.shade400)),
              ],
            )
          ],
          animate: true,
          defaultRenderer: new charts.ArcRendererConfig(arcWidth: 60)
        )
      ),
    );
  }
}

class TimeCard extends StatelessWidget
{
  final int c31;
  final int c7;
  final int c3;
  final bool awake;
  final String title;
  final int count;
  final MaterialColor sw;

  TimeCard({this.c31, this.c7, this.c3, this.awake, this.title, this.count, this.sw});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(3),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(title,
                style: TextStyle(
                  fontSize: 24
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text("$count Entries",
                style: TextStyle(
                  fontSize: 18
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(duration(c31),
                style: TextStyle(
                  fontSize: 16,
                  color: awake ? sw.shade900 : sw.shade100,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(duration(c7),
                style: TextStyle(
                  fontSize: 16,
                  color: awake ? sw.shade600 : sw.shade200,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(duration(c3),
                style: TextStyle(
                  fontSize: 16,
                  color: awake ? sw.shade400 : sw.shade300,
                ),
              ),
            ),
          ],
        )
      ),
    );
  }
}

class TextCard extends StatelessWidget
{
  final bool awake;
  final String title;
  final String text;
  final String title2;
  final String text2;
  final MaterialColor sw;

  TextCard({this.awake, this.title, this.title2, this.sw, this.text, this.text2});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(3),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(title,
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(text,
                style: TextStyle(
                  fontSize: 18, 
                  color: awake ? Colors.indigo.shade700 : Colors.indigo.shade200
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(title2,
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(7),
              child: Text(text2,
                style: TextStyle(
                  fontSize: 18,
                  color: awake ? Colors.deepPurple.shade700 : Colors.deepPurple.shade200
                ),
              ),
            ),
          ],
        )
      ),
    );
  }
}

class NocturnalEvent
{
  int ms;
  NocturnalAction action;
  NocturnalEvent(this.ms, this.action);

  String toString()
  {
    return "$ms:" + action.index.toString();
  }
}

class NocturnalEvents
{
  List<NocturnalEvent> events = new List<NocturnalEvent>();

  void add(NocturnalEvent e)
  {
    events.add(e);
  }

  void fromString(String s)
  {
    if(!s.contains("&"))
    {
      add(new NocturnalEvent(int.parse(s.split(":")[0]), NocturnalAction.values[int.parse(s.split(":")[1])]));
      return;
    }

    s.split("&").forEach((e) => add(new NocturnalEvent(int.parse(e.split(":")[0]), NocturnalAction.values[int.parse(e.split(":")[1])])));
  }

  String toString()
  {
    String f = "";
    events.forEach((e) => f += "&" + e.toString());

    if(f.length == 0)
    {
      return "";
    }

    return f.substring(1);
  }
}

class Cycle
{
  final int startTime;
  final int endTime;
  Cycle(this.startTime, this.endTime);

  int getDuration()
  {
    return endTime - startTime;
  }
}

enum NocturnalAction
{
  GOING_TO_SLEEP,
  WAKING_UP
}

class NocturnalCycleSegment
{
  int awake = 0;
  int percentCycle = 0;
  charts.Color color = charts.Color.black;

  NocturnalCycleSegment(this.awake, this.percentCycle, this.color);
}

class Nocons {
  Nocons._();
  static const _kFontFam = 'Nocons';
  static const IconData icons8_moon_symbol = const IconData(0xe800, fontFamily: _kFontFam);
  static const IconData icons8_sun = const IconData(0xe801, fontFamily: _kFontFam);
  static const IconData icons8_occupied_bed = const IconData(0xe802, fontFamily: _kFontFam);
}

String duration(int ms)
  {
    if(ms <= 0)
    {
      return "Unknown";
    }

    if(ms > 1000 * 60 * 60)
    {
      return ((ms / (1000 * 60 * 60)).toStringAsFixed(1) + " Hours").replaceFirst(".0", "");
    }

    if(ms > 1000 * 60)
    {
      return (ms / (1000 * 60)).round().toInt().toString() + " Minutes";
    }

    if(ms > 1000)
    {
      return (ms / 1000).round().toInt().toString() + " Seconds";
    }

    return "$ms Ms";
  }

  String durationsh(int ms)
  {
    if(ms <= 0)
    {
      return "Unknown";
    }

    if(ms > 1000 * 60 * 60)
    {
      return ((ms / (1000 * 60 * 60)).toStringAsFixed(1) + " Hours").replaceFirst(".0", "");
    }

    if(ms > 1000 * 60)
    {
      return (ms / (1000 * 60)).round().toInt().toString() + " Min";
    }

    if(ms > 1000)
    {
      return (ms / 1000).round().toInt().toString() + " Sec";
    }

    return "$ms Ms";
  }

  String minify(int m)
  {
    if(m < 10)
    {
      return "0$m";
    }

    return "$m";
  }

  int h12(int h24)
  {
    return (h24 + 1 > 12) ? (h24 - 12) : h24;
  }

  String ampm(int h)
  {
    return (h + 1 > 12) ? "PM" : "AM";
  }