package com.volmit.nocturnal;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.content.res.ColorStateList;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.os.Bundle;

import androidx.annotation.NonNull;

import com.google.android.material.bottomnavigation.BottomNavigationView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.cardview.widget.CardView;

import android.util.Log;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.FrameLayout;
import android.widget.RadioButton;
import android.widget.TextView;

import java.util.Objects;

public class Nocturnal extends AppCompatActivity {

    public static final String PROPERTIES_NOCTURNAL_LOG = "nocturnal_log";
    public static final String PROPERTIES_NOCTURNAL_SETTINGS = "nocturnal_settings";
    private FrameLayout activity;
    private FrameLayout status;
    private FrameLayout settings;
    private RadioButton radioLight;
    private RadioButton radioDark;
    private RadioButton radioOLED;
    private ThemeMode mode;
    private CardView cardSettings;
    private CardView cardDelete;
    private Button deleteCycleData;

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

    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        mode = ThemeMode.values()[getSharedPreferences(PROPERTIES_NOCTURNAL_SETTINGS, MODE_PRIVATE).getInt("theme", 0)];
        getSharedPreferences(PROPERTIES_NOCTURNAL_SETTINGS, MODE_PRIVATE).edit().putInt("theme", mode.ordinal()).apply();

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
        cardDelete = findViewById(R.id.wipe_card);
        deleteCycleData = findViewById(R.id.delete_cycle_data);
        deleteCycleData.setTextColor(getColor(R.color.colorBad));

        if(mode == ThemeMode.OLED)
        {
            cardSettings.setBackground(getDrawable(R.drawable.noled_bg));
            cardDelete.setBackground(getDrawable(R.drawable.noled_bg));
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

    @SuppressLint("ApplySharedPref")
    private void changeTheme(ThemeMode m)
    {
        this.mode = m;
        getSharedPreferences(PROPERTIES_NOCTURNAL_SETTINGS, MODE_PRIVATE).edit().putInt("theme", mode.ordinal()).commit();
        Log.v("THEME", "Theme is saved as " + mode.toString());
        finish();
        overridePendingTransition(R.anim.empty, R.anim.empty);
        Intent intent = (Intent) getIntent().clone();
        intent.putExtra("settings", true);
        startActivity(intent);
    }
}
