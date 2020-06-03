package sbm.cordova.plugin.epos2;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import android.content.Context;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import com.epson.epos2.Epos2Exception;
import com.epson.epos2.Log;
import com.epson.epos2.discovery.Discovery;
import com.epson.epos2.discovery.DiscoveryListener;
import com.epson.epos2.discovery.FilterOption;
import com.epson.epos2.discovery.DeviceInfo;
import com.epson.epos2.Epos2Exception;
import com.google.zxing.WriterException;
import com.epson.epos2.printer.Printer;
import com.epson.epos2.printer.PrinterStatusInfo;

import android.bluetooth.BluetoothAdapter;

import java.util.ArrayList;
import java.util.HashMap;
import java.io.IOException;

import com.google.zxing.common.BitMatrix;

import android.graphics.Bitmap;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.MultiFormatWriter;
import com.epson.epos2.printer.ReceiveListener;
import com.google.gson.Gson;


/**
 * This class echoes a string called from JavaScript.
 */
public class SbmCordovaPluginEpos2 extends CordovaPlugin implements ReceiveListener {

    private Context context;
    private String error = "";
    private ArrayList<JSONObject> mPrinterList = null;
    private FilterOption mFilterOption = null;
    private CallbackContext mCallbackContext;
    public static Printer mPrinter = null;
    int lang = 0;
    String method = "";
    String data = "";
    int alignText = 1;
    int addFeedLine = 1;
    int textSizeWidth = 1;
    int textSizeHeight = 1;
    int qrCodeWidth = 300;
    int qrCodeHeight = 300;
    int reverse = -2;
    int ul = -2;
    int em = 1;
    int color = -2;
    String printerTarget = "";
    int printerSeries = -1;
    String type;
    JSONArray values;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("coolMethod")) {

            String message = args.getString(0);
            this.coolMethod(message, callbackContext);
            return true;
        }

        if (action.equals("printText")) {
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    printText(args, callbackContext);

                }
            });

            return true;
        }


        if (action.equals("discoverPrinters")) {
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    discoverPrinters(args, callbackContext);
                }
            });
            return true;
        }


        if (action.equals("getPrintersList")) {

            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {

                    getPrintersList(args, callbackContext);
                }
            });
            return true;
        }


        if (action.equals("stopDiscoverPrinters")) {
            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run() {
                    stopDiscoverPrinters(args, callbackContext);
                }
            });
            return true;

        }


        return false;
    }


    private void coolMethod(String message, CallbackContext callbackContext) {
        if (message != null && message.length() > 0) {
            callbackContext.success(message);
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }
    }


    // Print Text
    private void printText(JSONArray args, CallbackContext callbackContext) {
        if (args != null) {

            try {
                JSONObject argsObject = args.getJSONObject(0);
                // Get printer Data
                if (!argsObject.has("printer")) {
                    callbackContext.error("Printer data required");
                }

                JSONObject printerData = argsObject.getJSONObject("printer");

                if ((!printerData.has("printerSeries")) || (!printerData.has("printerTarget"))) {
                    callbackContext.error("Printer data required");
                }

                printerTarget = printerData.getString("printerTarget");
                printerSeries = Integer.parseInt(printerData.getString("printerSeries"));
                if (printerData.has("lang")) {
                    lang = Integer.parseInt(printerData.getString("lang"));
                }
                values = argsObject.getJSONArray("data");
                mCallbackContext = callbackContext;
                runPrintSequence();
            } catch (JSONException e) {
                callbackContext.error("error");
            }

        }

    }


    // Get Printers List
    private void getPrintersList(JSONArray args, CallbackContext callbackContext) {
        if (args != null) {
            String json = new Gson().toJson(mPrinterList);
            callbackContext.success(json);
        } else {
            callbackContext.error("please don't pass an empty value");
        }
    }


    // Discover Printers
    private void discoverPrinters(JSONArray args, CallbackContext callbackContext) {

        // check if bluetooth is enabled

        BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if (mBluetoothAdapter == null) {
            callbackContext.error("Device does not support Bluetooth");
        } else {
            if (!mBluetoothAdapter.isEnabled()) {
                callbackContext.error("Bluetooth is not enabled");
            } else {
                mPrinterList = new ArrayList<JSONObject>();
                mPrinterList.clear();
                context = this.cordova.getActivity().getApplicationContext();
                mFilterOption = new FilterOption();
                mFilterOption.setDeviceType(Discovery.TYPE_ALL);
                mFilterOption.setEpsonFilter(Discovery.FILTER_NAME);
                try {
                    Discovery.start(context, mFilterOption, mDiscoveryListener);
                } catch (Exception e) {
                    callbackContext.error("Error on start discover");
                }
                callbackContext.success("success");
            }

        }
    }

    // Stop Discover Printers
    private void stopDiscoverPrinters(JSONArray args, CallbackContext callbackContext) {

        try {
            Discovery.stop();
        } catch (Exception e) {
            callbackContext.error("Error on start discover");
        }

        callbackContext.success("success");

    }


    private DiscoveryListener mDiscoveryListener = new DiscoveryListener() {
        @Override
        public void onDiscovery(final DeviceInfo deviceInfo) {
            cordova.getActivity().runOnUiThread(new Runnable() {
                public synchronized void run() {
                    HashMap<String, String> item = new HashMap<String, String>();
                    item.put("PrinterName", deviceInfo.getDeviceName());
                    item.put("Target", deviceInfo.getTarget());
                    JSONObject obj = new JSONObject(item);
                    mPrinterList.add(obj);
                }
            });
        }
    };


    private boolean initializePrinter(int printerSeries, int lang, String printerTarget) {

        context = this.cordova.getActivity().getApplicationContext();
        try {
            mPrinter = new Printer(printerSeries, lang, context);
        } catch (Exception e) {
            error = "Error onCreate new printer";
            return false;
        }

        if (mPrinter == null) {
            error = "Printer is null";
            return false;
        }


        PrinterStatusInfo status = mPrinter.getStatus();


        if (status.getPaper() == Printer.PAPER_NEAR_END) {
            error = "PAPER_NEAR_END";

            return false;

        }

        if (status.getBatteryLevel() == Printer.BATTERY_LEVEL_1) {
            error = "BATTERY_LEVEL_1";
            return false;
        }

        // open to Printer
        try {
            mPrinter.connect(printerTarget, Printer.PARAM_DEFAULT);
        } catch (Exception e) {
            error = "error connection " + Integer.toString(printerSeries) + " " + Integer.toString(lang) + " " + printerTarget;
            return false;
        }
        mPrinter.clearCommandBuffer();

        try {
            mPrinter.beginTransaction();
        } catch (Exception e) {
            error = "beginTransaction error ";
            return false;

        }

        return true;
    }


    private Bitmap encodeAsBitmap(String str) throws WriterException {
        BitMatrix result;
        try {
            result = new MultiFormatWriter().encode(str, BarcodeFormat.QR_CODE, 300, 300, null);
        } catch (IllegalArgumentException iae) {
            return null;
        }

        int width = result.getWidth();
        int height = result.getHeight();
        int[] pixels = new int[width * height];
        for (int y = 0; y < height; y++) {
            int offset = y * width;
            for (int x = 0; x < width; x++) {
                pixels[offset + x] = result.get(x, y) ? 0xFF000000 : 0xFFFFFFFF;
            }
        }

        Bitmap bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        bitmap.setPixels(pixels, 0, width, 0, 0, width, height);
        return bitmap;
    }

    private boolean isPrintable(PrinterStatusInfo status) {
        if (status == null) {
            return false;
        }

        if (status.getConnection() == Printer.FALSE) {
            return false;
        } else if (status.getOnline() == Printer.FALSE) {
            return false;
        } else {
            ;//print available
        }

        return true;
    }


    private String errorCreateData = "";

    // Create Data
    private boolean createData() {
        StringBuilder textData = new StringBuilder();

        try {

            for (int i = 0; i < values.length(); i++) {
                JSONObject jsonobject = values.getJSONObject(i);
                data = "";
                textData.delete(0, textData.length());
                if (jsonobject.has("type")) {
                    type = jsonobject.getString("type");


                    if (jsonobject.has("alignText")) {
                        alignText = Integer.parseInt(jsonobject.getString("alignText"));
                    }
                    if (jsonobject.has("addFeedLine")) {
                        addFeedLine = Integer.parseInt(jsonobject.getString("addFeedLine"));
                    }
                    if (jsonobject.has("textSizeWidth")) {
                        textSizeWidth = Integer.parseInt(jsonobject.getString("textSizeWidth"));
                    }
                    if (jsonobject.has("textSizeHeight")) {
                        textSizeHeight = Integer.parseInt(jsonobject.getString("textSizeHeight"));
                    }
                    if (jsonobject.has("styles")) {
                        JSONObject styles = jsonobject.getJSONObject("styles");

                        reverse = Integer.parseInt(styles.getString("reverse"));
                        ul = Integer.parseInt(styles.getString("ul"));
                        em = Integer.parseInt(styles.getString("em"));
                        color = Integer.parseInt(styles.getString("color"));
                    }
                    if (jsonobject.has("data")) {
                        data = jsonobject.getString("data");
                        textData.append(data);
                    }
                    if (jsonobject.has("qrCodeWidth")) {
                        qrCodeWidth = Integer.parseInt(jsonobject.getString("qrCodeWidth"));
                    }
                    if (jsonobject.has("qrCodeHeight")) {
                        qrCodeHeight = Integer.parseInt(jsonobject.getString("qrCodeHeight"));
                    }


                    try {

                        method = "addTextAlign";
                        mPrinter.addTextAlign(alignText);

                        method = "addTextSize";
                        mPrinter.addTextSize(textSizeWidth, textSizeHeight);


                        method = "addTextStyle";
                        mPrinter.addTextStyle(reverse, ul, em, color);


                        if (type.equals("qrCode")) {

                            method = "addImage";
                            mPrinter.addImage(encodeAsBitmap(textData.toString()), 0, 0, qrCodeWidth, qrCodeHeight, Printer.PARAM_DEFAULT, Printer.PARAM_DEFAULT, Printer.PARAM_DEFAULT, 3, Printer.PARAM_DEFAULT);
                        } else {
                            method = "addText";
                            mPrinter.addText(textData.toString());
                        }

                        method = "addFeedLine";
                        mPrinter.addFeedLine(addFeedLine);
                    } catch (Exception e) {
                        mCallbackContext.error("cannot create Data");


                    }

                }


            }

        } catch (JSONException e) {
            mCallbackContext.error("cannot parse data ");
        }
        return true;
    }


    @Override
    public void onPtrReceive(final Printer printerObj, final int code,
                             final PrinterStatusInfo status, final String printJobId) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public synchronized void run() {
                String msg = makeErrorMessage(status);
                if (msg.equals("")) {
                    mCallbackContext.success("PRINT_SUCCESS");

                } else {
                    mCallbackContext.error(msg);

                }


                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        disconnectPrinter();
                    }
                }).start();
            }
        });
    }


    private void disconnectPrinter() {
        if (mPrinter == null) {
            return;
        }

        try {
            mPrinter.endTransaction();
        } catch (final Exception e) {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public synchronized void run() {
                    mCallbackContext.error("endTransaction execptipnnn");
                }
            });
        }

        try {
            mPrinter.disconnect();
        } catch (final Exception e) {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public synchronized void run() {
                    mCallbackContext.error("disconnect execptipnnn");

                }
            });
        }

        finalizeObject();
    }


    private boolean connectPrinter() {
        boolean isBeginTransaction = false;

        if (mPrinter == null) {
            return false;
        }

        try {
            mPrinter.connect(printerTarget, Printer.PARAM_DEFAULT);
        } catch (Exception e) {
            mCallbackContext.error("connect connect to printer");
            return false;
        }

        try {
            mPrinter.beginTransaction();
            isBeginTransaction = true;
        } catch (Exception e) {
            mCallbackContext.error("beginTransaction problem");

        }

        if (isBeginTransaction == false) {
            try {
                mPrinter.disconnect();
            } catch (Epos2Exception e) {
                // Do nothing
                return false;
            }
        }
        return true;
    }

    private void finalizeObject() {
        if (mPrinter == null) {
            return;
        }

        mPrinter.clearCommandBuffer();

        mPrinter.setReceiveEventListener(null);

        mPrinter = null;
    }

    private boolean initializeObject() {
        try {
            mPrinter = new Printer(printerSeries, lang, context);
        } catch (Exception e) {
            mCallbackContext.error("cannot create object Printer");
            return false;
        }

        mPrinter.setReceiveEventListener(this);

        return true;
    }


    private boolean printData() {
        if (mPrinter == null) {
            return false;
        }

        if (!connectPrinter()) {
            return false;
        }

        PrinterStatusInfo status = mPrinter.getStatus();


        if (!isPrintable(status)) {

            mCallbackContext.error(makeErrorMessage(status));
            try {
                mPrinter.disconnect();
            } catch (Exception ex) {
                // Do nothing
            }
            return false;
        }

        try {


            mPrinter.sendData(Printer.PARAM_DEFAULT);
        } catch (Exception e) {

            mCallbackContext.error("error on sendData to Printer");

            try {
                mPrinter.disconnect();
            } catch (Exception ex) {
                // Do nothing
            }
            return false;
        }

        return true;
    }


    private String makeErrorMessage(PrinterStatusInfo status) {
        String msg = "";

        if (status.getOnline() == Printer.FALSE) {
            msg += "online";
        }
        if (status.getConnection() == Printer.FALSE) {
            msg += "getConnection";

        }
        if (status.getCoverOpen() == Printer.TRUE) {
            msg += "getCoverOpen";

        }
        if (status.getPaper() == Printer.PAPER_EMPTY) {
            msg += "PAPER_EMPTY";

        }
        if (status.getPaperFeed() == Printer.TRUE || status.getPanelSwitch() == Printer.SWITCH_ON) {
            msg += "SWITCH_ON";

        }
        if (status.getErrorStatus() == Printer.MECHANICAL_ERR || status.getErrorStatus() == Printer.AUTOCUTTER_ERR) {
            msg += "AUTOCUTTER_ERR";

        }
        if (status.getErrorStatus() == Printer.UNRECOVER_ERR) {
            msg += "UNRECOVER_ERR";

        }
        if (status.getErrorStatus() == Printer.AUTORECOVER_ERR) {
            msg += "AUTORECOVER_ERR";


        }
        if (status.getBatteryLevel() == Printer.BATTERY_LEVEL_0) {
            msg += "BATTERY_LEVEL_0";

        }

        return msg;
    }


    private boolean runPrintSequence() {
        if (!initializeObject()) {
            return false;
        }
        if (!createData()) {
            finalizeObject();
            return false;
        }

        if (!printData()) {
            finalizeObject();
            return false;
        }

        return true;
    }


}
