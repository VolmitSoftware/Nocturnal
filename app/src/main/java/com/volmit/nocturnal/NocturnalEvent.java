package com.volmit.nocturnal;

import android.graphics.PorterDuff;

import java.lang.reflect.Type;

public class NocturnalEvent
{
    private long time;
    private long duration;
    private NocturnalEventType type;

    public NocturnalEvent(long time, NocturnalEventType type)
    {
        this(time, -1, type);
    }
    public NocturnalEvent(long time, long duration, NocturnalEventType type)
    {
        this.time = time;
        this.type = type;
        this.duration = duration;
    }

    public NocturnalEvent(long time, String data)
    {
        this.time = time;

        if(data.contains(":"))
        {
            type = NocturnalEventType.values()[Integer.valueOf(data.split("\\Q:\\E")[0])];
            duration = Long.valueOf(data.split("\\Q:\\E")[1]);
        }

        else
        {
            type = NocturnalEventType.values()[Integer.valueOf(data)];
            duration = -1;
        }
    }

    public String toString()
    {
        if(type.equals(NocturnalEventType.FULL_CYCLE))
        {
            return type.ordinal() + ":" + duration;
        }

        return type.ordinal() + "";
    }

    public static NocturnalEvent ofSleep()
    {
        return of(NocturnalEventType.SLEEP);
    }
    public static NocturnalEvent ofWake()
    {
        return of(NocturnalEventType.WAKE);
    }
    public static NocturnalEvent ofSleep(long time)
    {
        return of(time, NocturnalEventType.SLEEP);
    }

    public static NocturnalEvent ofWake(long time)
    {
        return of(time, NocturnalEventType.WAKE);
    }

    public static NocturnalEvent ofFullCycle(long time, long duration)
    {
        return new NocturnalEvent(time, duration, NocturnalEventType.FULL_CYCLE);
    }

    public static NocturnalEvent of(NocturnalEventType type)
    {
        return new NocturnalEvent(System.currentTimeMillis(), type);
    }

    public static NocturnalEvent of(long time, NocturnalEventType type)
    {
        return new NocturnalEvent(time, type);
    }

    public long getTime()
    {
        return time;
    }

    public NocturnalEventType getType()
    {
        return type;
    }

    public long getDuration()
    {
        return duration;
    }
}
