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
  int avgCycleLength = 0;

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

  List<Cycle> getRecentCycles(int maxCycles)
  {
    bool enter = false;
    int start = 0;
    int end = 0;
    List<Cycle> cycles = new List<Cycle>();

    for(int i = events.events.length - 1; i > 0; i--)
    {
      NocturnalEvent e = events.events[i];

      if(!enter && e.action == NocturnalAction.WAKING_UP)
      {
        enter = true;
        end = e.ms;
      }

      else if(enter && e.action == NocturnalAction.GOING_TO_SLEEP && end > 0)
      {
        enter = false;
        start = e.ms;
        cycles.add(new Cycle(start, end));
      }

      if(cycles.length >= maxCycles)
      {
        break;
      }
    }

    return cycles;
  }

  int computeAverageCycleTime(int maxCycles)
  {
    double avg = 0;
    int itr = 0;

    getRecentCycles(maxCycles).forEach((c) {
      avg += c.getDuration();
      itr++;
    });

    if(itr == 0)
    {
      return 0;
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

  void updateCalculations()
  {
    avgCycleLength = computeAverageCycleTime(3); 
  }

  @override
  Widget build(BuildContext context) {
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(awake ? "Awake" : "Asleep"),
            Text(events.events.length.toString() + " Entries"),
            Text(avgCycleLength.toString() + " Avg Cycle Length")
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => toggleAwake(),
        tooltip: 'Sleep',
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
