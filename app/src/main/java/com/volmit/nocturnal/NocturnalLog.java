package com.volmit.nocturnal;

import java.util.ArrayList;
import java.util.List;

public class NocturnalLog
{
    private List<NocturnalEvent> events;

    public NocturnalLog()
    {
        events = new ArrayList<>();
    }

    public void log(NocturnalEvent ofSleep) {
        events.add(ofSleep);
    }

    public List<NocturnalEvent> getEvents() {
        return events;
    }
}
