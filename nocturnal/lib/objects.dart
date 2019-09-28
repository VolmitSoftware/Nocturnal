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
    s.split("&").forEach((e) => add(new NocturnalEvent(int.parse(e.split(":")[0]), NocturnalAction.values[int.parse(e.split(":")[1])])));
  }

  String toString()
  {
    String f = "";
    events.forEach((e) => f += "&" + e.toString());

    return f.substring(1);
  }
}

enum NocturnalAction
{
  GOING_TO_SLEEP,
  WAKING_UP
}