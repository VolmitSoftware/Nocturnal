package com.volmit.nocturnal;

import android.annotation.TargetApi;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.drawable.Icon;
import android.os.Build;
import android.service.quicksettings.TileService;
import android.util.EventLog;
import android.widget.Toast;

public class NocturnalTileService extends TileService
{
    @Override
    public void onDestroy() {
        super.onDestroy();
    }

    @Override
    public void onTileAdded() {
        super.onTileAdded();
    }

    @Override
    public void onTileRemoved() {
        super.onTileRemoved();
    }

    @Override
    public void onStartListening() {
        super.onStartListening();
    }

    @Override
    public void onStopListening() {
        super.onStopListening();
    }

    @Override
    public void onClick()
    {
        super.onClick();
        Logger.saveLog(getApplicationContext(), Logger.isAwake(getApplicationContext()) ? NocturnalEvent.ofSleep() : NocturnalEvent.ofWake());
        boolean awake = Logger.isAwake(getApplicationContext());
        getQsTile().setLabel(awake ? "Fall Sleep" : "Wake Up");
        getQsTile().setIcon(Icon.createWithResource(getApplicationContext(), awake ? R.drawable.baseline_hotel_black_18dp : R.drawable.baseline_wb_sunny_black_18dp));
        getQsTile().updateTile();

        if(awake)
        {
            Toast.makeText(getApplicationContext(), "Rise and Shine!", Toast.LENGTH_LONG).show();
        }

        else
        {
            Toast.makeText(getApplicationContext(), "Good Night!", Toast.LENGTH_LONG).show();
        }

        try
        {
            Nocturnal.reload();
        }

        catch(Throwable e)
        {

        }
    }
}