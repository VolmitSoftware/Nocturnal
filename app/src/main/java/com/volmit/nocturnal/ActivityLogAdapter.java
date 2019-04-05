package com.volmit.nocturnal;

import android.content.Context;
import android.content.res.ColorStateList;
import android.graphics.PorterDuff;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.text.DateFormat;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;

import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.RecyclerView;

public class ActivityLogAdapter extends androidx.recyclerview.widget.RecyclerView.Adapter<ActivityLogAdapter.NocturnalViewHolder> {

    private List<NocturnalEvent> events;
    private Context context;

  public ActivityLogAdapter(Context context, List<NocturnalEvent> events) {
    this.events = events;
    this.context = context;
  }

  @NonNull
  @Override
  public NocturnalViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
    return new NocturnalViewHolder((FrameLayout) LayoutInflater.from(parent.getContext()).inflate(R.layout.activity_card, parent, false));
  }

  @Override
  public void onBindViewHolder(@NonNull NocturnalViewHolder holder, int position) {
    NocturnalEvent event = events.get(position);
      NocturnalEvent previous = position + 1 < events.size() ? events.get(position + 1) : null;
      NocturnalEvent next = position > 0 ? events.get(position - 1) : null;
    CardView cv = holder.v.findViewById(R.id.card);
    ImageView iv = holder.v.findViewById(R.id.image);
    TextView tv = holder.v.findViewById(R.id.description);
    TextView tvs = holder.v.findViewById(R.id.description_small);
    List<String> add = new ArrayList<>();
    if(event.getType().equals(NocturnalEventType.FULL_CYCLE))
    {
        iv.setImageResource(R.drawable.baseline_pie_chart_black_18dp);
        iv.setImageTintList(ColorStateList.valueOf(context.getColor(R.color.colorCycle)));
        tv.setText("Full Cycle " + time(event.getTime()));
    }

    else if(event.getType().equals(NocturnalEventType.SLEEP))
    {
        iv.setImageResource(R.drawable.baseline_hotel_black_18dp);
        iv.setImageTintList(ColorStateList.valueOf(context.getColor(R.color.colorSleep)));
        tv.setText("Fell Asleep " + time(event.getTime()));

        if(previous != null && previous.getType().equals(NocturnalEventType.WAKE))
        {
            long duration = event.getTime() - previous.getTime();
            add.add("Was Awake for " + timeLong(duration, 1));
        }

        if(position == 0)
        {
            add.add("Still \"Sleeping\"");
        }
    }

    else if(event.getType().equals(NocturnalEventType.WAKE))
    {
        iv.setImageResource(R.drawable.baseline_wb_sunny_black_18dp);
        iv.setImageTintList(ColorStateList.valueOf(context.getColor(R.color.colorWake)));
        tv.setText("Woke up " + time(event.getTime()));

        if(previous != null && previous.getType().equals(NocturnalEventType.SLEEP))
        {
            long duration = event.getTime() - previous.getTime();
            add.add("Was Asleep for " + timeLong(duration, 1));
        }

        if(position == 0)
        {
            add.add("Still Awake");
        }
    }

    String f = "";

    for(String i : add)
    {
        f += "\n" + i;
    }

    if(f.isEmpty() || f.length() < 2)
    {
        tvs.setVisibility(View.GONE);
    }

    else
    {
        tvs.setText(f.substring(1));
    }

      cv.setOutlineProvider(android.view.ViewOutlineProvider.BOUNDS);
      cv.setClipToOutline(false);

      if(Nocturnal.isOLED())
      {
          cv.setBackground(context.getDrawable(R.drawable.noled_bg_bottom));
      }
  }

    public static String f(double i, int p)
    {
        String form = "#";

        if(p > 0)
        {
            form = form + "." + repeat("#", p);
        }

        DecimalFormat DF = new DecimalFormat(form);

        return DF.format(i);
    }

    public static String repeat(String s, int n)
    {
        if(s == null)
        {
            return null;
        }

        final StringBuilder sb = new StringBuilder();

        for(int i = 0; i < n; i++)
        {
            sb.append(s);
        }

        return sb.toString();
    }

    public static String timeLong(long ms, int prec)
    {
        if(ms < 1000.0)
        {
            return f(ms, prec) + "ms";
        }

        if(ms / 1000.0 < 60.0)
        {
            return f(ms / 1000.0, prec) + " seconds";
        }

        if(ms / 1000.0 / 60.0 < 60.0)
        {
            return f(ms / 1000.0 / 60.0, prec) + " minutes";
        }

        if(ms / 1000.0 / 60.0 / 60.0 < 24.0)
        {
            return f(ms / 1000.0 / 60.0 / 60.0, prec) + " hours";
        }

        if(ms / 1000.0 / 60.0 / 60.0 / 24.0 < 7)
        {
            return f(ms / 1000.0 / 60.0 / 60.0 / 24.0, prec) + " days";
        }

        return f(ms, prec) + "ms";
    }

  public String time(long time)
  {
      Calendar cd = Calendar.getInstance();
      cd.setTimeInMillis(time);
      Calendar cc = Calendar.getInstance();
      boolean sameday = false;
      DateFormat df = new SimpleDateFormat("yy");
      String formattedDate = df.format(Calendar.getInstance().getTime());
      String timeString = "";
      int hour = cd.get(Calendar.HOUR_OF_DAY);
      String minute = (cd.get(Calendar.MINUTE) <= 9 ? "0" : "") + cd.get(Calendar.MINUTE);
      if (hour == 0) {
          timeString =  "12:" + minute + " AM (Midnight)";
      } else if (hour < 12) {
          timeString = hour + ":" + minute + " AM";
      } else if (hour == 12) {
          timeString = "12:" + minute + " PM (Noon)";
      } else {
          timeString = (hour - 12) + ":" + minute + " PM";
      }

      if(cc.get(Calendar.DAY_OF_MONTH) == cd.get(Calendar.DAY_OF_MONTH) && cc.get(Calendar.MONTH) == cd.get(Calendar.MONTH) && cc.get(Calendar.YEAR) == cd.get(Calendar.YEAR))
      {
          return "Today at " + timeString;
      }

      else if(cc.get(Calendar.DAY_OF_MONTH) == cd.get(Calendar.DAY_OF_MONTH) + 1 && cc.get(Calendar.MONTH) == cd.get(Calendar.MONTH) && cc.get(Calendar.YEAR) == cd.get(Calendar.YEAR))
      {
          return "Yesterday at " + timeString;
      }

      else if(cc.get(Calendar.YEAR) == cd.get(Calendar.YEAR))
      {
          return "On " + (cd.get(Calendar.MONTH) + 1) + "/" + (cd.get(Calendar.DAY_OF_MONTH)) + " at  " + timeString;
      }

      else
      {
          return "On " + (cd.get(Calendar.MONTH) + 1) + "/" + (cd.get(Calendar.DAY_OF_MONTH)) + "/" + formattedDate + " at  " + timeString;
      }
  }

  @Override
  public int getItemCount() {
    return events.size();
  }

  public static class NocturnalViewHolder extends RecyclerView.ViewHolder
  {
    public FrameLayout v;
    public NocturnalViewHolder(FrameLayout v) {
      super(v);
      this.v = v;
    }
  }
}