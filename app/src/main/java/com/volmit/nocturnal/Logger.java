package com.volmit.nocturnal;

import android.content.Context;
import android.content.SharedPreferences;

import java.security.PrivateKey;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;

public class Logger {

    public static final String PROPERTIES_NOCTURNAL_LOG = "nocturnal_log";
    public static final String PROPERTIES_NOCTURNAL_LOG_CACHE = "nocturnal_log_cache";
    public static final String PROPERTIES_NOCTURNAL_SETTINGS = "nocturnal_settings";

    public static long getLatestTime(Context ctx)
    {
        return ctx.getSharedPreferences(PROPERTIES_NOCTURNAL_LOG_CACHE, Context.MODE_PRIVATE).getLong("latest", -1);
    }

    public static boolean isAwake(Context ctx)
    {
        return !isSleeping(ctx);
    }

    public static boolean isSleeping(Context ctx)
    {
        if(!hasLatestLog(ctx))
        {
            return false;
        }

        return getLatestLog(ctx).getType().equals(NocturnalEventType.SLEEP);
    }

    public static boolean hasLatestLog(Context ctx)
    {
        return getLatestLog(ctx) != null;
    }

    public static NocturnalEvent getLatestLog(Context ctx)
    {
        long m = -1;
        String f = ctx.getSharedPreferences(PROPERTIES_NOCTURNAL_LOG, Context.MODE_PRIVATE).getString((m = getLatestTime(ctx)) + "", null);

        if(f == null)
        {
            return null;
        }

        return new NocturnalEvent(m, f);
    }

    public static void loadLog(Context ctx, NocturnalLog log)
    {
        Map<String, ?> m = ctx.getSharedPreferences(PROPERTIES_NOCTURNAL_LOG, ctx.MODE_PRIVATE).getAll();
        List<Long> longs = new ArrayList<>();
        for(String i : m.keySet())
        {
            long time = Long.valueOf(i);
            longs.add(time);
        }

        Collections.sort(longs);
        Collections.reverse(longs);

        for(Long i : longs)
        {
            String data = m.get("" + i).toString();
            log.log(new NocturnalEvent(i, data));
        }
    }

    public static void clearLog(Context ctx)
    {
        ctx.getSharedPreferences(PROPERTIES_NOCTURNAL_LOG, ctx.MODE_PRIVATE).edit().clear().commit();
        saved(ctx, null);
    }

    public static void saveLog(Context ctx, NocturnalLog log)
    {
        SharedPreferences.Editor m = ctx.getSharedPreferences(PROPERTIES_NOCTURNAL_LOG, ctx.MODE_PRIVATE).edit().clear();
        NocturnalEvent e = null;
        for(NocturnalEvent i : log.getEvents())
        {
            m.putString(i.getTime() + "", i.toString());
            e = i;
        }

        saved(ctx, e);

        m.commit();
    }

    public static void saved(Context ctx, NocturnalEvent e)
    {
        if(e == null)
        {
            ctx.getSharedPreferences(PROPERTIES_NOCTURNAL_LOG_CACHE, ctx.MODE_PRIVATE).edit().remove("latest").commit();
        }

        else
        {
            ctx.getSharedPreferences(PROPERTIES_NOCTURNAL_LOG_CACHE, ctx.MODE_PRIVATE).edit().putLong("latest", e.getTime()).commit();
        }
    }

    public static void saveLog(Context ctx, NocturnalEvent e)
    {
        ctx.getSharedPreferences(PROPERTIES_NOCTURNAL_LOG, ctx.MODE_PRIVATE).edit().putString(e.getTime() + "", e.toString()).commit();
        saved(ctx, e);
    }
}
