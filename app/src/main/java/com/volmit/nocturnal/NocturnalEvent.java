package com.volmit.nocturnal;

public class NocturnalEvent
{
    private long time;
    private NocturnalEventType type;

    public NocturnalEvent(long time, NocturnalEventType type)
    {
        this.time = time;
        this.type = type;
    }

    public static NocturnalEvent ofSleep()
    {
        return of(NocturnalEventType.SLEEP);
    }
    public static NocturnalEvent ofWake()
    {
        return of(NocturnalEventType.WAKE);
    }


    public static NocturnalEvent of(NocturnalEventType type)
    {
        return new NocturnalEvent(System.currentTimeMillis(), type);
    }
}
