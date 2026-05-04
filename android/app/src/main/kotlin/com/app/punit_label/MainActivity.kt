package com.punitinstrument.punitlabel
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.ByteArrayOutputStream
//import androidx.core.app.ActivityCompat
//import androidx.core.content.ContextCompat
import com.snbc.sdk.LabelPrinter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
class MainActivity : FlutterActivity() {
    init {
        System.loadLibrary("ConfigFileINI")
        System.loadLibrary("SimpleLogModule")   // dependency first
        System.loadLibrary("LabelPrinterSDK")   // main SDK
    }
    private val CHANNEL = "label_printer"
    private var printer: LabelPrinter? = null
    //    private var sdkInitialized = false
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("LabelPrinterSDK", "🟢 MainActivity onCreate called")
        println("🟢 MainActivity onCreate called")
        try {
            Log.i("LabelPrinterSDK", "🟡 Initializing LabelPrinter SDK...")
            printer = LabelPrinter()
            println("✅ LabelPrinter SDK fully initialized")
        }catch (e: Exception){
            Log.e("LabelPrinterSDK", "❌ SDK init exception: ${e.message}")
            println("❌ SDK init exception: ${e.message}")
        }

    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        println("🟢 configureFlutterEngine called")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {
                    "connectPrinter" -> connectPrinter(call, result)
                    "disconnectPrinter" -> disconnectPrinter(result)
                    "getPrinterStatus" -> getPrinterStatus(result)
                    // New: Test sticker with custom size
                    "printTestSticker" -> {
                        val args = call.arguments as? Map<String, Any> ?: emptyMap()

                        val width = (args["width"] as? Number)?.toInt() ?: 700
                        val height = (args["height"] as? Number)?.toInt() ?: 623
                        val margin = (args["margin"] as? Number)?.toInt() ?: 20
                        val thickness = (args["thickness"] as? Number)?.toInt() ?: 8
                        val isGrid = args["isGrid"] as? Boolean ?: false
                        val isWhiteLabel = args["isWhiteLabel"] as? Boolean ?: false
                        val printTime = args["printTime"] as? Boolean ?: false
                        val companyName = args["companyName"]?.toString() ?: ""
                        val companyContact = args["companyContact"]?.toString() ?: ""
                        val barcodeData = args["barcodeData"]?.toString() ?: ""
                        val productName = args["productName"]?.toString() ?: ""
                        val rawAttributes = call.argument<List<Map<String, Any>>>("attributes") ?: emptyList()
                        val layout = call.argument<Map<String, Any>>("layout") ?: emptyMap()
                        val attributes = rawAttributes.map { it.mapValues { v -> v.value.toString() } }
                        val businessHours = args["businessHours"]?.toString() ?: ""

                        printTrySticker(
                            result = result,
                            width = width,
                            height = height,
                            margin = margin,
                            thickness = thickness,
                            isGrid = isGrid,
                            isWhiteLabel = isWhiteLabel,
                            printTime = printTime,
                            companyName = companyName,
                            companyContact = companyContact,
                            barcodeData = barcodeData,
                            productName = productName,
                            attributes = attributes,
                            layout = layout,
                            businessHours = businessHours,

                        )
                    }
                    "printTeaSticker" -> {
                        val args = call.arguments as? Map<String, Any> ?: emptyMap()

                        val width = (args["width"] as? Number)?.toInt() ?: 600
                        val height = (args["height"] as? Number)?.toInt() ?: 410
                        val margin = (args["margin"] as? Number)?.toInt() ?: 0

                        val companyName = args["companyName"]?.toString() ?: "Majedar Tea Co."
                        val productName = args["productName"]?.toString() ?: ""
                        val description = args["description"]?.toString() ?: ""
                        val grossWt = args["grossWt"]?.toString() ?: ""
                        val barcodeData = args["barcodeData"]?.toString() ?: ""

                        val rawAttributes =
                            call.argument<List<Map<String, Any>>>("attributes") ?: emptyList()

                        val attributes =
                            rawAttributes.map { it.mapValues { v -> v.value.toString() } }

                        val isGrid = args["isGrid"] as? Boolean ?: false
                        val isWhiteLabel = args["isWhiteLabel"] as? Boolean ?: false
                        val printTime = args["printTime"] as? Boolean ?: false

                        printTeaSticker(
                            result = result,
                            width = width,
                            height = height,
                            margin = margin,
                            companyName = companyName,
                            productName = productName,
                            description = description,
                            grossWt = grossWt,
                            barcodeData = barcodeData,
                            attributes = attributes,
                            isGrid = isGrid,
                            isWhiteLabel = isWhiteLabel,
                            printTime = printTime
                        )
                    }

//                    "printTeaSticker" -> {
//                        val args = call.arguments as? Map<String, Any> ?: emptyMap()
//
//                        val width = (args["width"] as? Number)?.toInt() ?: 600
//                        val height = (args["height"] as? Number)?.toInt() ?: 410
//                        val margin = (args["margin"] as? Number)?.toInt() ?: 0
//                        val companyName = args["companyName"]?.toString() ?: "Majedar Tea Co."
//                        val barcodeData = args["barcodeData"]?.toString() ?: ""
//
//                        val rawAttributes =
//                            call.argument<List<Map<String, Any>>>("attributes") ?: emptyList()
//
//                        val attributes =
//                            rawAttributes.map { it.mapValues { v -> v.value.toString() } }
//
//                        val isWhiteLabel = args["isWhiteLabel"] as? Boolean ?: false
//                        val printTime = args["printTime"] as? Boolean ?: false
//
//                        printTeaSticker(
//                            result = result,
//                            width = width,
//                            height = height,
//                            margin = margin,
//                            companyName = companyName,
//                            barcodeData = barcodeData,
//                            attributes = attributes,
//                            isWhiteLabel = isWhiteLabel,
//                            printTime = printTime
//                        )
//                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun connectPrinter(call: MethodCall, result: MethodChannel.Result) {
        val mac = call.argument<String>("mac") ?: ""
        Thread {
            try {
                if (printer == null) printer = LabelPrinter()

                // Discover Bluetooth printers
                val discoveredPrinters: Array<String> = printer?.DiscoverPrinter(7, 10000) ?: emptyArray()
                Log.d("LabelPrinterSDK", "Discovered printers: ${discoveredPrinters.joinToString()}")

                if (!discoveredPrinters.any { it.contains(mac) }) {
                    mainHandler.post {
                        result.error(
                            "MAC_NOT_FOUND",
                            "Printer with MAC $mac not found nearby or paired",
                            null
                        )
                    }
                    return@Thread
                }

                // Optional delay
                Thread.sleep(1000)

                // Attempt connection
                var status = printer?.ConnectPrinter(7, mac, 2) ?: -1

                // Retry once if failed
                if (status != 0) {
                    Thread.sleep(500)
                    status = printer?.ConnectPrinter(7, mac, 2) ?: -1
                }

                mainHandler.post {
                    if (status == 0) {
                        Log.d("LabelPrinterSDK", "Connected to printer: $mac")
                        result.success("Connected to printer: $mac")
                    } else {
                        result.error(
                            "CONNECTION_ERROR",
                            "Failed to connect, status code: $status. Ensure printer is paired and on.",
                            null
                        )
                    }
                }

            } catch (e: Exception) {
                mainHandler.post {
                    result.error(
                        "CONNECTION_EXCEPTION",
                        e.message ?: "Unknown exception during printer connection",
                        null
                    )
                }
            }
        }.start()
    }

    private fun getPrinterStatus(result: MethodChannel.Result) {
        Thread {
            try {
                val lp = printer
                if (lp == null) {
                    mainHandler.post {
                        result.success(
                            mapOf(
                                "connected" to false,
                                "message" to "Printer object is null"
                            )
                        )
                    }
                    return@Thread
                }

                val status = lp.GetStatus()
                val code = lp.errorNo

                if (code == 3) {
                    // COMMUNICATION ERROR → printer OFF or disconnected
                    mainHandler.post {
                        result.success(
                            mapOf(
                                "connected" to false,
                                "message" to "Printer unreachable (error 3)"
                            )
                        )
                    }
                    return@Thread
                }


                if (status == null) {
                    // Null status means printer not connected or communication failure
                    mainHandler.post {
                        result.success(
                            mapOf(
                                "connected" to false,
                                "message" to "Failed to read printer status"
                            )
                        )
                    }
                    return@Thread
                }

                // If printer status is available, return all fields
                mainHandler.post {
                    result.success(
                        mapOf(
                            "connected" to true,
                            "is_ready_to_print" to status.is_ready_to_print,
                            "is_paused" to status.is_paused,
                            "is_paper_out" to status.is_paper_out,
                            "is_head_opened" to status.is_head_opened,
                            "is_ribbon_out" to status.is_ribbon_out,
                            "is_cutter_error" to status.is_cutter_error,
                            "is_printer_busy" to status.is_printer_busy
                        )
                    )
                }

            } catch (e: Exception) {
                mainHandler.post {
                    result.success(
                        mapOf(
                            "connected" to false,
                            "message" to (e.message ?: "Unknown error")
                        )
                    )
                }
            }
        }.start()
    }

    // ===== Center Helper =====
    private fun centerText(text: String, fontSize: Int, labelWidth: Int): Int {
        val estWidth = text.length * fontSize / 2.2
        return ((labelWidth - estWidth) / 2).toInt()
    }

    private fun printTrySticker(
        result: MethodChannel.Result,
        width: Int = 700,
        height: Int = 623,
        margin: Int = 30,
        thickness: Int = 8,
        isGrid: Boolean = false,
        isWhiteLabel: Boolean = false,
        printTime: Boolean = false,
        attributes: List<Map<String, String>> = emptyList(),
        companyName: String = "NIVA GROUP INDIA",
        companyContact: String = "TEL: +91-7573830094  |  WWW.NIVAGROUPINDIA.COM",
        barcodeData: String = "123456789012",
        productName: String = "123456789012",
        layout: Map<String, Any>,
        businessHours: String = "",


    )   {
        Thread {
            try {
                val timeStamp = SimpleDateFormat(
                    "dd-MM-yyyy HH:mm",
                    Locale.getDefault()
                ).format(Date())
                val lp = printer ?: run {
                    mainHandler.post { result.error("NO_PRINTER", "Printer not connected", null) }
                    return@Thread
                }

                val setSize = lp.SetLabelSize(width, height)
                if (setSize != 0) {
                    mainHandler.post { result.error("SET_LABEL_ERROR", "Failed: $setSize", null) }
                    return@Thread
                }

                lp.SetPrintDensity(15)

                // ===== Layout config from Flutter =====
                val maxAttributes = (layout["maxAttributes"] as? Number)?.toInt() ?: attributes.size
                val lineHeight = (layout["lineHeight"] as? Number)?.toInt() ?: 60
                val keyFont = (layout["keyFont"] as? Number)?.toInt() ?: 30
                val valueFont = (layout["valueFont"] as? Number)?.toInt() ?: 34
                val bottomPadding = (layout["bottomPadding"] as? Number)?.toInt() ?: 150
                val columnGap = (layout["columnGap"] as? Number)?.toInt() ?: 200
                val barcodeHeight =
                    (layout["barcodeHeight"] as? Number)?.toInt() ?: 80

                val left = margin
                val top = margin
                val right = width - margin
                val bottom = height - margin
                //val titleFont = 40
                val titleFont = if (businessHours.isNotEmpty()) 56 else 40
                val contactFont = 26
                /// If White Label is True then dont print the Company name and company details and if false print the company name and details
                //val companyX = (width / 2) - (companyName.length * titleFont / 4)
                var yPos = top + 20
                var companyY = 0


                if (!isWhiteLabel) {
                    val companyX = left + 20
                    companyY = yPos
                    lp.PrintText(companyX, companyY, "0", companyName, 0, titleFont, titleFont, 0)

                    val contactLines = companyContact.split("\n")
                    val contactX = left + 20
                    var contactY = companyY + 70
                    for (line in contactLines) {
                        if (line.isNotBlank()) {
                            lp.PrintText(
                                contactX,
                                contactY,
                                "0",
                                line,
                                0,
                                contactFont,
                                contactFont,
                                0
                            )
                            contactY += 30   // line spacing (adjust if needed)
                        }
                    }
// ← ADD THIS BLOCK HERE (before yPos line)
if (businessHours.isNotEmpty()) {
    lp.PrintText(contactX, contactY, "0", businessHours, 0, contactFont, contactFont, 0)
    contactY += 30
}
                    yPos = contactY + 10
                }else{
                    yPos = top + 20
                }
                // ---------- DATE & TIME (SAFE FOR SMALL LABELS) ----------
                if (printTime) {
                    val dateTimeFont = 20          // smaller font
                    val lineGap = 22               // tight spacing

                    val dateFormat = SimpleDateFormat("dd-MM-yyyy", Locale.getDefault())
                    val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())

                    val dateText = dateFormat.format(Date())
                    val timeText = timeFormat.format(Date())

                    val dateX = right - 150
                    //var dateY = companyY
                    var dateY = if (businessHours.isNotEmpty()) yPos else companyY  // Move down ONLY for Wholesale Pack
                    if (businessHours.isNotEmpty()) {
                        yPos += 50  // Add spacing before WHOLESALE PACK title ONLY for Wholesale Pack
                    }
                    // Date (line 1)
                    lp.PrintText(
                        dateX,
                        dateY,
                        "0",
                        dateText,
                        0,
                        dateTimeFont,
                        dateTimeFont,
                        0
                    )

                    // Time (line 2)
                    lp.PrintText(
                        dateX,
                        dateY + lineGap,
                        "0",
                        timeText,
                        0,
                        dateTimeFont,
                        dateTimeFont,
                        0
                    )
                }
                // --- after contact printing, define centers & bounds ---
                val cx = width / 2
                val cy = height / 2
               // val lineHeight = 60
                // --- PRODUCT NAME ---
                //val productFont = 34
                val productFont = if (businessHours.isNotEmpty()) 56 else 34
                // --- WHOLESALE PACK TITLE (only for Wholesale Pack format) ---
                if (businessHours.isNotEmpty()) {
                    val titleText = "Wholesale Pack"
                    val titleFont = 56
                    val titleX = centerText(titleText, titleFont, width)
                    lp.PrintText(titleX, yPos, "0", titleText, 0, titleFont, titleFont, 1) // bold
                    yPos += 70  // space below title
                }
                
                //val productX = isGrid ? (width / 2) - (productName.length * productFont / 4) : left + 20
                //val productX = left + 20
                val displayName = if (businessHours.isNotEmpty() && productName.contains(":- "))
                    productName.substringAfter(":- ")
                else
                    productName

                // Calculate maximum font size that fits on one line
                // The formula is derived from centerText: estWidth = text.length * fontSize / 2.2
                val maxTextWidth = width - 40 // 20 dots margin on each side
                var dynamicProductFont = if (businessHours.isNotEmpty()) {
                    val maxFitSize = (maxTextWidth * 2.2 / displayName.length).toInt()
                    // Cap it at 56 (7mm) maximum, but don't go smaller than 24
                    maxFitSize.coerceIn(24, 56)
                } else {
                    34
                }
                val productX = if (businessHours.isNotEmpty())
                    centerText(displayName, dynamicProductFont, width)   // center for Wholesale Pack
                else
                    left + 20 

                val productY = yPos

                lp.PrintText(productX, productY, "0", displayName, 0, dynamicProductFont, dynamicProductFont, 0)

// update yPos to start attributes below product name
                //yPos = productY + 40
                yPos = productY + if (businessHours.isNotEmpty()) 80 else 40

// Print attributes (unchanged logic, but uses cx for better alignment)
                if (attributes.isNotEmpty()) {
                    if (!isGrid) {
                        for (item in attributes) {
                            //if (yPos > bottom - 150) break
                            if (yPos > bottom - bottomPadding) break

                            val key = item["key"] ?: ""
                            val value = item["value"] ?: ""

                            // left column offset relative to center
                            val keyX = left + 20
                            //val valX = keyX + 200
                            val valX = keyX + columnGap

                            lp.PrintText(keyX, yPos, "0", "$key:", 0, keyFont, keyFont, 0)
                            lp.PrintText(valX, yPos, "0", value, 0, valueFont, valueFont, 0)

                            yPos += lineHeight
                        }
                    } else {
                        val col1X = left + 20
                        val col2X = width / 2 + 20

                        for (i in attributes.indices step 2) {
                           // if (yPos > bottom - 150) break
                            if (yPos > bottom - bottomPadding) break

                            val first = attributes[i]
                            val second = attributes.getOrNull(i + 1)

                            lp.PrintText(col1X, yPos, "0", "${first["key"]}:", 0, keyFont, keyFont, 0)
                            lp.PrintText(col1X + columnGap, yPos, "0", first["value"] ?: "", 0, valueFont, valueFont, 0)

                            if (second != null) {
                                lp.PrintText(col2X, yPos, "0", "${second["key"]}:", 0, keyFont, keyFont, 0)
                                lp.PrintText(
                                    col2X + columnGap,
                                    yPos,
                                    "0",
                                    second["value"] ?: "",
                                    0,
                                    valueFont,
                                    valueFont,
                                    0
                                )
                            }

                            yPos += lineHeight
                        }
                    }
                } else {
                    // Default no-attribute test
                    lp.PrintText(cx - 180, 220, "0", "TEST STICKER", 0, 40, 40, 1)
                    lp.PrintText(cx - 200, 290, "0", "Size: ${width}×${height}", 0, 30, 30, 0)
                    lp.PrintText(cx - 200, 350, "0", "Printer Connected ✔", 0, 30, 30, 0)
                }

                val humanReadableHeight = 28   // printer-dependent, safe avg
                val footerFont = 20
                val footerHeight = footerFont + 10
                val footerY = bottom - footerHeight
// --- BARCODE + FOOTER (improved centering & module width sync) ---
               // val barcodeHeight = 80
                //val barcodeY = bottom - barcodeHeight - 50
                val barcodeBlockHeight = barcodeHeight + humanReadableHeight
                val barcodeGap = 12  // breathing space
                val barcodeY = footerY - barcodeBlockHeight - barcodeGap

// available horizontal printable width inside margins
                val availableWidth = (right - left) - 20   // leave a small safety padding

// start with a conservative module width (tweak if your SDK uses different units)
                var moduleWidth = 4

// rough estimated modules-per-char factor (symbology dependent; 6 is a conservative guess)
                val modulesPerChar = 6

                // estimate printed barcode width
                fun estimateBarcodeWidth(chars: Int, moduleW: Int): Int {
                    return chars * moduleW * modulesPerChar
                }

                var estimatedBarcodeWidth = estimateBarcodeWidth(barcodeData.length, moduleWidth)

// if estimated width doesn't fit, reduce moduleWidth until it fits (or until 1)
                while (estimatedBarcodeWidth > availableWidth && moduleWidth > 1) {
                    moduleWidth -= 1
                    estimatedBarcodeWidth = estimateBarcodeWidth(barcodeData.length, moduleWidth)
                }

// final clamp — if still too big, force-fit by capping to availableWidth
                if (estimatedBarcodeWidth > availableWidth) {
                    estimatedBarcodeWidth = availableWidth
                }

// center the barcode inside printable area (left + padding + half remaining)
                var barcodeX = left + 20 // + ((availableWidth - estimatedBarcodeWidth) / 4)

// Use the same moduleWidth in the PrintBarcode1D call — this is crucial
                val barcodeStatus = lp.PrintBarcode1D(
                    barcodeX,
                    barcodeY,
                    1,
                    0,
                    barcodeData,
                    barcodeHeight,
                    1,
                    moduleWidth,   // was 4
                    moduleWidth    // was 4
                )

                if (barcodeStatus != 0) {
                    mainHandler.post {
                        result.error(
                            "BARCODE_ERROR",
                            "Failed: $barcodeStatus",
                            null
                        )
                    }
                    return@Thread
                }

// --- FOOTER: place just below barcode (or just above if you prefer), but inside bounds ---
                val footerText = "Label generated from weighing ERP by punitinstrument.com"
                //val footerFont = 20

// simple estimate for footer width (avg char ≈ 0.5 * fontSize)
                val footerTextWidth = (footerText.length * footerFont * 0.5).toInt()
                var footerX = left + 20 + ((availableWidth - footerTextWidth) / 4)
                if (footerX < left + 5) footerX = left + 5
                if (footerX + footerTextWidth > right - 5) footerX = right - footerTextWidth - 5

                if (!isWhiteLabel) {
                lp.PrintText(footerX, footerY, "0", footerText, 0, footerFont, footerFont, 0)
                }
                // ================================================
                // 8️⃣ SEND PRINT JOB
                // ================================================
                val status = lp.PrintLabel(1, 2)

                mainHandler.post {
                    if (status == 0) {
                        result.success("Sticker printed successfully!")
                    } else {
                        result.error("PRINT_FAILED", "PrintLabel returned: $status", null)
                    }
                }

            } catch (e: Exception) {
                mainHandler.post { result.error("EXCEPTION", e.message ?: "Unknown", null) }
            }

        }.start()
    }

//    private fun printTeaSticker(
//        result: MethodChannel.Result,
//        width: Int = 600,
//        height: Int = 410,
//        margin: Int = 0,
//        companyName: String = "Majedar Tea Co.",
//        barcodeData: String = "",
//        attributes: List<Map<String, String>> = emptyList(),
//        isWhiteLabel: Boolean = false,
//        printTime: Boolean = false,
//        layout: Map<String, Any> = emptyMap()
//    ) {
//        Thread {
//            try {
//                val lp = printer ?: run {
//                    mainHandler.post {
//                        result.error("NO_PRINTER", "Printer not connected", null)
//                    }
//                    return@Thread
//                }
//
//                val setSize = lp.SetLabelSize(width, height)
//                if (setSize != 0) {
//                    mainHandler.post {
//                        result.error("SET_LABEL_ERROR", "Failed: $setSize", null)
//                    }
//                    return@Thread
//                }
//
//                lp.SetPrintDensity(15)
//
//                // ----------- LAYOUT CONFIG (Optimized for 1-2 attributes) -----------
//                val lineHeight = (layout["lineHeight"] as? Number)?.toInt() ?: 70
//                val keyFont = (layout["keyFont"] as? Number)?.toInt() ?: 34
//                val valueFont = (layout["valueFont"] as? Number)?.toInt() ?: 38
//                val columnGap = (layout["columnGap"] as? Number)?.toInt() ?: 210
//                val bottomPadding = (layout["bottomPadding"] as? Number)?.toInt() ?: 120
//                val barcodeHeight = (layout["barcodeHeight"] as? Number)?.toInt() ?: 55
//
//                val left = margin
//                val top = margin
//                val right = width - margin
//                val bottom = height - margin
//
//                var yPos = top + 25
//
//                // ----------- HEADER (COMPANY NAME) -----------
//                if (!isWhiteLabel) {
//                    val titleFont = 46
//
//                    lp.PrintText(
//                        left + 60,
//                        yPos,
//                        "0",
//                        companyName,
//                        0,
//                        titleFont,
//                        titleFont,
//                        1
//                    )
//
//                    yPos += 95   // large gap like handwritten layout
//                }
//
//                // ----------- DATE TIME (OPTIONAL) -----------
//                if (printTime) {
//                    val dateFormat = SimpleDateFormat("dd-MM-yyyy", Locale.getDefault())
//                    val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
//
//                    lp.PrintText(
//                        right - 150,
//                        top + 20,
//                        "0",
//                        dateFormat.format(Date()),
//                        0,
//                        20,
//                        20,
//                        0
//                    )
//
//                    lp.PrintText(
//                        right - 150,
//                        top + 42,
//                        "0",
//                        timeFormat.format(Date()),
//                        0,
//                        20,
//                        20,
//                        0
//                    )
//                }
//
//                // ----------- ATTRIBUTES (KEY : VALUE) -----------
//                if (attributes.isNotEmpty()) {
//
//                    val keyX = left + 30
//                    val valueX = keyX + columnGap
//
//                    for (item in attributes.take(3)) { // 🔥 restrict to 2 for clean layout
//                        if (yPos > bottom - bottomPadding) break
//
//                        val key = item["key"] ?: ""
//                        val value = item["value"] ?: ""
//
//                        lp.PrintText(keyX, yPos, "0", "$key :", 0, keyFont, keyFont, 1)
//                        lp.PrintText(valueX, yPos, "0", value, 0, valueFont, valueFont, 1)
//
//                        yPos += lineHeight
//                    }
//
//                } else {
//                   // lp.PrintText(left + 30, yPos, "0", "No Data", 0, 30, 30, 1)
//                }
//
//                // ----------- BARCODE -----------
//                val barcodeY = bottom - barcodeHeight - 75
//                val barcodeX = left + 80
//
//                val barcodeStatus = lp.PrintBarcode1D(
//                    barcodeX,
//                    barcodeY,
//                    1,
//                    0,
//                    barcodeData,
//                    barcodeHeight,
//                    1,
//                    3,
//                    3
//                )
//
//                if (barcodeStatus != 0) {
//                    mainHandler.post {
//                        result.error("BARCODE_ERROR", "Failed: $barcodeStatus", null)
//                    }
//                    return@Thread
//                }
//
//                // ----------- PRINT -----------
//                val status = lp.PrintLabel(1, 1)
//
//                mainHandler.post {
//                    if (status == 0) {
//                        result.success("Tea sticker printed successfully!")
//                    } else {
//                        result.error("PRINT_FAILED", "PrintLabel returned: $status", null)
//                    }
//                }
//
//            } catch (e: Exception) {
//                mainHandler.post {
//                    result.error("EXCEPTION", e.message ?: "Unknown error", null)
//                }
//            }
//        }.start()
//    }

    private fun printTeaSticker(
        result: MethodChannel.Result,
        width: Int = 600,
        height: Int = 410,
        margin: Int = 0,
        companyName: String = "Majedar Tea Co.",
        productName: String = "",
        description: String = "",
        grossWt: String = "",
        barcodeData: String = "",
        attributes: List<Map<String, String>> = emptyList(),
        isGrid: Boolean = false,
        isWhiteLabel: Boolean = false,
        printTime: Boolean = false
    ) {
        Thread {
            try {
                val lp = printer ?: run {
                    mainHandler.post {
                        result.error("NO_PRINTER", "Printer not connected", null)
                    }
                    return@Thread
                }

                val setSize = lp.SetLabelSize(width, height)
                if (setSize != 0) {
                    mainHandler.post {
                        result.error("SET_LABEL_ERROR", "Failed: $setSize", null)
                    }
                    return@Thread
                }

                lp.SetPrintDensity(15)

                val left = margin
                val right = width - margin

//                // ---------- BORDER ----------
//                lp.PrintBox(left, margin, right, height - margin, 3)

                // ---------- HEADER ----------
                val titleFont = 45
                if (isWhiteLabel == false) {
                    lp.PrintText(
                        left + 35,
                        35,
                        "0",
                        companyName,
                        0,
                        titleFont,
                        titleFont,
                        1
                    )
                    // ---------- PRODUCT ----------
                    lp.PrintText(
                        left + 25,
                        100,
                        "0",
                        "Product :",
                        0,
                        36,
                        36,
                        1
                    )

                    lp.PrintText(
                        left + 190,
                        100,
                        "0",
                        productName,
                        0,
                        36,
                        36,
                        1
                    )
                    lp.PrintText(
                        left + 25,
                        160,
                        "0",
                        "Description :",
                        0,
                        36,
                        36,
                        1
                    )

                    lp.PrintText(
                        left + 260,
                        160,
                        "0",
                        description,
                        0,
                        36,
                        36,
                        1
                    )

                    // ---------- GROSS WT ----------
                    lp.PrintText(
                        left + 25,
                        220,
                        "0",
                        "Gross Wt :",
                        0,
                        36,
                        36,
                        1
                    )

                    lp.PrintText(
                        left + 260,
                        220,
                        "0",
                        grossWt,
                        0,
                        36,
                        36,
                        1
                    )

                    // ---------- BARCODE ----------
                    val barcodeHeight = 60
                    val barcodeY = height - 130
                    val barcodeX = left + 50

                    lp.PrintBarcode1D(
                        barcodeX,
                        barcodeY,

                        1,
                        0,
                        barcodeData,
                        barcodeHeight,
                        1,
                        3,
                        3
                    )
                }else {
                    // ---------- PRODUCT ----------
                    lp.PrintText(
                        left + 25,
                        50,
                        "0",
                        "Product :",
                        0,
                        45,
                        45,
                        1
                    )

                    lp.PrintText(
                        left + 190,
                        50,
                        "0",
                        productName,
                        0,
                        45,
                        45,
                        1
                    )


                // ---------- DESCRIPTION ----------
                lp.PrintText(
                    left + 25,
                    120,
                    "0",
                    "Description :",
                    0,
                    40,
                    40,
                    1
                )

                lp.PrintText(
                    left + 260,
                    120,
                    "0",
                    description,
                    0,
                    40,
                    40,
                    1
                )

                // ---------- GROSS WT ----------
                lp.PrintText(
                    left + 25,
                    180,
                    "0",
                    "Gross Wt :",
                    0,
                    40,
                    40,
                    1
                )

                lp.PrintText(
                    left + 260,
                    180,
                    "0",
                    grossWt,
                    0,
                    40,
                    40,
                    1
                )

                // ---------- BARCODE ----------
                val barcodeHeight = 100
                val barcodeY = height - 170
                val barcodeX = left + 50

                lp.PrintBarcode1D(
                    barcodeX,
                    barcodeY,

                    1,
                    0,
                    barcodeData,
                    barcodeHeight,
                    1,
                    3,
                    3
                )

                }

                // ---------- PRINT ----------
                val status = lp.PrintLabel(1, 1)

                mainHandler.post {
                    if (status == 0) {
                        result.success("Tea label printed successfully!")
                    } else {
                        result.error("PRINT_FAILED", "PrintLabel returned: $status", null)
                    }
                }

            } catch (e: Exception) {
                mainHandler.post {
                    result.error("EXCEPTION", e.message ?: "Unknown error", null)
                }
            }
        }.start()
    }


    private fun disconnectPrinter(result: MethodChannel.Result) {
        Thread {
            try {
                val status = printer?.Disconnect() ?: -1
                printer = null
                mainHandler.post {
                    result.success("Disconnected (status=$status)")
                }
            } catch (e: Exception) {
                mainHandler.post {
                    result.error("DISCONNECT_ERROR", e.message ?: "Unknown error during disconnect", null)
                }
            }
        }.start()
    }
}