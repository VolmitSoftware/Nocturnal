package com.volmit.nocturnal;

import android.annotation.SuppressLint;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.ColorStateList;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.os.Bundle;

import androidx.annotation.NonNull;

import com.google.android.material.bottomnavigation.BottomNavigationView;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.text.Html;
import android.util.Log;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.RadioButton;
import android.widget.TextView;
import android.widget.Toast;

import java.security.PrivateKey;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public class Nocturnal extends AppCompatActivity {

    private FrameLayout activity;
    private FrameLayout status;
    private FrameLayout settings;
    private RadioButton radioLight;
    private RadioButton radioDark;
    private RadioButton radioOLED;
    private ThemeMode mode;
    private CardView cardSettings;
    private CardView cardDelete;
    private CardView cardSummary;
    private Button deleteCycleData;
    private RecyclerView recyclerView;
    private ImageView sicon;
    private NocturnalLog log;
    private ActivityLogAdapter logAdapter;
    private static Nocturnal instance;

    private BottomNavigationView.OnNavigationItemSelectedListener mOnNavigationItemSelectedListener
            = new BottomNavigationView.OnNavigationItemSelectedListener() {

        @Override
        public boolean onNavigationItemSelected(@NonNull MenuItem item) {
            activity.setVisibility(View.GONE);
            status.setVisibility(View.GONE);
            settings.setVisibility(View.GONE);

            switch (item.getItemId()) {
                case R.id.navigation_activity:
                    activity.setVisibility(View.VISIBLE);
                    return true;
                case R.id.navigation_status:
                    status.setVisibility(View.VISIBLE);
                    return true;
                case R.id.navigation_settings:
                    settings.setVisibility(View.VISIBLE);
                    return true;
            }

            return false;
        }
    };

    public static void reload()
    {
        instance.log = new NocturnalLog();
        Logger.loadLog(instance, instance.log);
        instance.logAdapter = new ActivityLogAdapter(instance, instance.log.getEvents());
        instance.recyclerView.setAdapter(instance.logAdapter);
        instance.recyclerView.setLayoutManager(new LinearLayoutManager(instance));
    }

    protected void onResume() {
        super.onResume();
        logAdapter = new ActivityLogAdapter(this, log.getEvents());
        recyclerView.setAdapter(logAdapter);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
    }

    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        instance = this;
        log = new NocturnalLog();
        Logger.loadLog(this, log);
        mode = ThemeMode.values()[getSharedPreferences(Logger.PROPERTIES_NOCTURNAL_SETTINGS, MODE_PRIVATE).getInt("theme", 0)];
        getSharedPreferences(Logger.PROPERTIES_NOCTURNAL_SETTINGS, MODE_PRIVATE).edit().putInt("theme", mode.ordinal()).apply();

        Log.v("THEME", "Theme is loaded as " + mode.toString());

        if(mode.equals(ThemeMode.OLED))
        {
            setTheme(R.style.OLED);
        }

        else
        {
            setTheme(R.style.NocturnalDayNight);
            AppCompatDelegate.setDefaultNightMode(ThemeMode.LIGHT.equals(mode) ? AppCompatDelegate.MODE_NIGHT_NO : AppCompatDelegate.MODE_NIGHT_YES);
        }

        setContentView(R.layout.activity_nocturnal);
        radioLight = findViewById(R.id.lightmode);
        radioDark = findViewById(R.id.darkmode);
        radioOLED = findViewById(R.id.oledmode);
        activity = findViewById(R.id.activity);
        status = findViewById(R.id.status);
        settings = findViewById(R.id.settings);
        activity.setVisibility(View.GONE);
        status.setVisibility(View.GONE);
        settings.setVisibility(View.GONE);
        activity.setVisibility(View.VISIBLE);
        cardSettings = findViewById(R.id.settings_card);
        cardSummary = findViewById(R.id.summary_card);
        cardDelete = findViewById(R.id.wipe_card);
        deleteCycleData = findViewById(R.id.delete_cycle_data);
        deleteCycleData.setTextColor(getColor(R.color.colorBad));
        recyclerView = findViewById(R.id.recycler);
        logAdapter = new ActivityLogAdapter(this, log.getEvents());
        recyclerView.setAdapter(logAdapter);
        sicon = findViewById(R.id.sicon);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));

        if(mode == ThemeMode.OLED)
        {
            cardSettings.setBackground(getDrawable(R.drawable.noled_bg));
            cardDelete.setBackground(getDrawable(R.drawable.noled_bg));
            cardSummary.setBackground(getDrawable(R.drawable.noled_bg));
        }

        if(isDarkOrOLED())
        {
            sicon.setImageTintList(ColorStateList.valueOf(getColor(R.color.colorOLEDGray)));
        }

        switch(mode)
        {
            case LIGHT:
                radioLight.setChecked(true);
                break;
            case DARK:
                radioDark.setChecked(true);
                break;
            case OLED:
                radioOLED.setChecked(true);
                break;
        }

        deleteCycleData.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                areYouSure("Delete All Sleep Cycle Data?", "Are you sure you want to wipe all cycle data from this device? It will take possibly weeks of new data before prediction will appear again.", "Delete Cycle Data", new Runnable() {
                    @Override
                    public void run() {
                        Logger.clearLog(Nocturnal.this);
                        reload();
                        Toast.makeText(Nocturnal.this, "Deleted all cycle data", Toast.LENGTH_LONG).show();
                    }
                });
            }
        });

        radioLight.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(isChecked)
                {
                    changeTheme(ThemeMode.LIGHT);
                }
            }
        });

        radioDark.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(isChecked)
                {
                    changeTheme(ThemeMode.DARK);
                }
            }
        });

        radioOLED.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(isChecked)
                {
                    changeTheme(ThemeMode.OLED);
                }
            }
        });

        BottomNavigationView navigation = findViewById(R.id.navigation);
        navigation.setOnNavigationItemSelectedListener(mOnNavigationItemSelectedListener);

        if(mode.equals(ThemeMode.OLED))
        {
            Objects.requireNonNull(getSupportActionBar()).setBackgroundDrawable(new ColorDrawable(getResources().getColor(R.color.colorOLEDBlack)));
        }

        if(getIntent().getBooleanExtra("settings", false))
        {
            navigation.setSelectedItemId(R.id.navigation_settings);
        }
    }

    public static boolean isOLED()
    {
        return ThemeMode.values()[Nocturnal.instance.getSharedPreferences(Logger.PROPERTIES_NOCTURNAL_SETTINGS, MODE_PRIVATE).getInt("theme", 0)].equals(ThemeMode.OLED);
    }

    public static boolean isDarkOrOLED()
    {
        return !isLight();
    }

    public static boolean isDark()
    {
        return ThemeMode.values()[Nocturnal.instance.getSharedPreferences(Logger.PROPERTIES_NOCTURNAL_SETTINGS, MODE_PRIVATE).getInt("theme", 0)].equals(ThemeMode.DARK);
    }

    public static boolean isLight()
    {
        return ThemeMode.values()[Nocturnal.instance.getSharedPreferences(Logger.PROPERTIES_NOCTURNAL_SETTINGS, MODE_PRIVATE).getInt("theme", 0)].equals(ThemeMode.LIGHT);
    }

    @SuppressLint("ApplySharedPref")
    private void changeTheme(ThemeMode m)
    {
        this.mode = m;
        getSharedPreferences(Logger.PROPERTIES_NOCTURNAL_SETTINGS, MODE_PRIVATE).edit().putInt("theme", mode.ordinal()).commit();
        Log.v("THEME", "Theme is saved as " + mode.toString());
        finish();
        overridePendingTransition(R.anim.empty, R.anim.empty);
        Intent intent = (Intent) getIntent().clone();
        intent.putExtra("settings", true);
        startActivity(intent);
    }

    private void areYouSure(String title, String message, String action, final Runnable did)
    {
        AlertDialog.Builder dialogBuilder = new AlertDialog.Builder(this)
                .setTitle(title)
                .setMessage(message)
                .setPositiveButton(action, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int whichButton) {
                        did.run();
                        dialog.dismiss();
                    }
                })
                .setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int whichButton)
                    {
                        dialog.dismiss();
                    }
                });

        AlertDialog dialog = dialogBuilder.show();
    }
}
