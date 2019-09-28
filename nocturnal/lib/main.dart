import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as log;

void main() => runApp(NocturnalApp());

int timeMs()
{
   return DateTime.now().millisecondsSinceEpoch;
}

class NocturnalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nocturnal',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light
      ),
      home: Nocturnal(title: 'Nocturnal'),
    );
  }
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
  }

  int computeFullCycleCount()
  {
    return (events.events.length / 2).floor().toInt();
  }

  int computeHalfCycleCount(NocturnalAction side)
  {
    return events.events.length - (events.events.length % 2 == 0 ? 0 : 1);
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
  }

  String duration(int ms)
  {
    if(ms <= 0)
    {
      return "Unknown";
    }

    if(ms > 1000 * 60 * 60)
    {
      return (ms / 1000 * 60 * 60).toStringAsPrecision(1) + " Hours";
    }

    if(ms > 1000 * 60)
    {
      return (ms / 1000 * 60).round().toInt().toString() + " Minutes";
    }

    if(ms > 1000)
    {
      return (ms / 1000).round().toInt().toString() + " Seconds";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: awake ? Colors.indigo : Colors.deepPurple,
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
                          color: awake ? Colors.indigo.shade700 : Colors.deepPurple.shade800
                        ),
                      ),
                    ),
                  ],
                )
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text("Full Cycle",
                        style: TextStyle(
                          fontSize: 24
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text("$fullCount Entries",
                        style: TextStyle(
                          fontSize: 18
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text(duration(avgCycleLength31),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text(duration(avgCycleLength7),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text(duration(avgCycleLength3),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.indigo.shade400
                        ),
                      ),
                    ),
                  ],
                )
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text("Night Cycle",
                        style: TextStyle(
                          fontSize: 24
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text("$nightCount Entries",
                        style: TextStyle(
                          fontSize: 18
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text(duration(avgNightCycleLength31),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text(duration(avgNightCycleLength7),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text(duration(avgNightCycleLength3),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.indigo.shade400
                        ),
                      ),
                    ),
                  ],
                )
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text("Day Cycle",
                        style: TextStyle(
                          fontSize: 24
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text("$dayCount Entries",
                        style: TextStyle(
                          fontSize: 18
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text(duration(avgDayCycleLength31),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text(duration(avgDayCycleLength7),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.indigo.shade600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(7),
                      child: Text(duration(avgDayCycleLength3),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.indigo.shade400
                        ),
                      ),
                    ),
                  ],
                )
              ),
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

class Nocons {
  Nocons._();
  static const _kFontFam = 'Nocons';
  static const IconData icons8_moon_symbol = const IconData(0xe800, fontFamily: _kFontFam);
  static const IconData icons8_sun = const IconData(0xe801, fontFamily: _kFontFam);
  static const IconData icons8_occupied_bed = const IconData(0xe802, fontFamily: _kFontFam);
}
