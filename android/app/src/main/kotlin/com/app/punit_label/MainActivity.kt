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
                        val attributeLabel =
                            args["attributeLabel"]?.toString()?.takeIf { it.isNotBlank() }
                                ?: "Description"
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
                            attributeLabel = attributeLabel,
                            description = description,
                            grossWt = grossWt,
                            barcodeData = barcodeData,
                            attributes = attributes,
                            isGrid = isGrid,
                            isWhiteLabel = isWhiteLabel,
                            printTime = printTime
                        )
                    }
                    "printDryFruitSticker" -> {
                        val args = call.arguments as? Map<String, Any> ?: emptyMap()

                        val width = (args["width"] as? Number)?.toInt() ?: 600
                        val height = (args["height"] as? Number)?.toInt() ?: 410
                        val margin = (args["margin"] as? Number)?.toInt() ?: 0

                        val companyName = args["companyName"]?.toString() ?: "Majedar Tea Co."
                        val productName = args["productName"]?.toString() ?: ""
                        val attributeLabel =
                            args["attributeLabel"]?.toString()?.takeIf { it.isNotBlank() }
                                ?: "Description"
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

                        printDryFruitSticker(
                            result = result,
                            width = width,
                            height = height,
                            margin = margin,
                            companyName = companyName,
                            productName = productName,
                            attributeLabel = attributeLabel,
                            description = description,
                            grossWt = grossWt,
                            barcodeData = barcodeData,
                            attributes = attributes,
                            isGrid = isGrid,
                            isWhiteLabel = isWhiteLabel,
                            printTime = printTime
                        )
                    }
                    "printNeoLabelSticker" -> {
                        val args = call.arguments as? Map<String, Any> ?: emptyMap()

                        val width = (args["width"] as? Number)?.toInt() ?: 700
                        val height = (args["height"] as? Number)?.toInt() ?: 600
                        val margin = (args["margin"] as? Number)?.toInt() ?: 0
                        val companyName = args["companyName"]?.toString() ?: ""
                        val address = args["address"]?.toString() ?: ""
                        val phone = args["phone"]?.toString() ?: ""
                        val email = args["email"]?.toString() ?: ""
                        val productName = args["productName"]?.toString() ?: ""
                        val barcodeData = args["barcodeData"]?.toString() ?: ""
                        val serialNumber = args["serialNumber"]?.toString() ?: ""
                        val printSerialNumber = args["printSerialNumber"] as? Boolean ?: false
                        val rawAttributes =
                            call.argument<List<Map<String, Any>>>("attributes") ?: emptyList()
                        val attributes =
                            rawAttributes.map { it.mapValues { v -> v.value.toString() } }
                        val layout = call.argument<Map<String, Any>>("layout") ?: emptyMap()
                        val isWhiteLabel = args["isWhiteLabel"] as? Boolean ?: false
                        val printTime = args["printTime"] as? Boolean ?: false

                        printNeoLabelSticker(
                            result = result,
                            width = width,
                            height = height,
                            margin = margin,
                            companyName = companyName,
                            address = address,
                            phone = phone,
                            email = email,
                            productName = productName,
                            barcodeData = barcodeData,
                            serialNumber = serialNumber,
                            printSerialNumber = printSerialNumber,
                            attributes = attributes,
                            layout = layout,
                            isWhiteLabel = isWhiteLabel,
                            printTime = printTime
                        )
                    }
                    "printSmallSevenLabelSticker" -> {
                        val args = call.arguments as? Map<String, Any> ?: emptyMap()

                        val width = (args["width"] as? Number)?.toInt() ?: 700
                        val height = (args["height"] as? Number)?.toInt() ?: 600
                        val margin = (args["margin"] as? Number)?.toInt() ?: 0
                        val companyName = args["companyName"]?.toString() ?: ""
                        val address = args["address"]?.toString() ?: ""
                        val phone = args["phone"]?.toString() ?: ""
                        val email = args["email"]?.toString() ?: ""
                        val productName = args["productName"]?.toString() ?: ""
                        val barcodeData = args["barcodeData"]?.toString() ?: ""
                        val serialNumber = args["serialNumber"]?.toString() ?: ""
                        val printSerialNumber = args["printSerialNumber"] as? Boolean ?: false
                        val rawAttributes =
                            call.argument<List<Map<String, Any>>>("attributes") ?: emptyList()
                        val attributes =
                            rawAttributes.map { it.mapValues { v -> v.value.toString() } }
                        val layout = call.argument<Map<String, Any>>("layout") ?: emptyMap()
                        val isWhiteLabel = args["isWhiteLabel"] as? Boolean ?: false
                        val printTime = args["printTime"] as? Boolean ?: false

                        printSmallSevenLabelSticker(
                            result = result,
                            width = width,
                            height = height,
                            margin = margin,
                            companyName = companyName,
                            address = address,
                            phone = phone,
                            email = email,
                            productName = productName,
                            barcodeData = barcodeData,
                            serialNumber = serialNumber,
                            printSerialNumber = printSerialNumber,
                            attributes = attributes,
                            layout = layout,
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

    private fun fitFontSizeForWidth(
        text: String,
        maxWidth: Int,
        preferredFont: Int,
        minFont: Int = 20
    ): Int {
        val cleanText = text.trim()
        if (cleanText.isEmpty()) return preferredFont

        val estimatedFit = (maxWidth * 2.2 / cleanText.length).toInt()
        return estimatedFit.coerceIn(minFont, preferredFont)
    }

    private fun splitByLength(text: String, maxChars: Int): List<String> {
        val cleanText = text.trim()
        if (cleanText.isEmpty()) return emptyList()

        val chunks = mutableListOf<String>()
        var start = 0
        while (start < cleanText.length) {
            val end = (start + maxChars).coerceAtMost(cleanText.length)
            chunks.add(cleanText.substring(start, end))
            start = end
        }
        return chunks
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
                val status = lp.PrintLabel(1, 1)

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
        attributeLabel: String = "Description",
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
                val teaTimeStamp = if (printTime) {
                    SimpleDateFormat("dd-MM-yyyy HH:mm", Locale.getDefault()).format(Date())
                } else {
                    ""
                }
                val displayProductName = productName.trim()
                val displayDescription = description.trim()
                val displayAttributeLabel = attributeLabel.trim().ifBlank { "Description" }
                val displayAttributeText = if (displayDescription.isBlank()) {
                    displayAttributeLabel
                } else {
                    "$displayAttributeLabel : $displayDescription"
                }
                val displayWeight = grossWt.trim().let {
                    when {
                        it.isEmpty() -> ""
                        it.lowercase(Locale.getDefault()).endsWith("kg") -> it
                        else -> "$it Kg"
                    }
                }
                val printableAttributes = attributes.filter {
                    (it["key"] ?: "").isNotBlank() && (it["value"] ?: "").isNotBlank()
                }.take(3)

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
                    if (teaTimeStamp.isNotEmpty()) {
                        lp.PrintText(
                            right - 235,
                            35,
                            "0",
                            teaTimeStamp,
                            0,
                            24,
                            24,
                            1
                        )
                    }

                    // ---------- PRODUCT ----------
                    val productFont = fitFontSizeForWidth(
                        displayProductName,
                        (right - left - 50).coerceAtLeast(200),
                        36,
                        28
                    )
                    lp.PrintText(
                        left + 25,
                        100,
                        "0",
                        displayProductName,
                        0,
                        productFont,
                        productFont,
                        1
                    )
                    var attributeY = 148
                    if (printableAttributes.isNotEmpty()) {
                        for (item in printableAttributes) {
                            val line = "${item["key"] ?: ""} : ${item["value"] ?: ""}"
                            val rowFont = fitFontSizeForWidth(
                                line,
                                (right - left - 50).coerceAtLeast(220),
                                30,
                                22
                            )
                            lp.PrintText(
                                left + 25,
                                attributeY,
                                "0",
                                line,
                                0,
                                rowFont,
                                rowFont,
                                1
                            )
                            attributeY += rowFont + 6
                        }
                    } else {
                        val attributeFont = 32
                        val attributeLineHeight = 36
                        val attributeMaxChars =
                            (((right - left - 50) * 2.2) / attributeFont).toInt().coerceAtLeast(18)
                        val attributeLines =
                            splitByLength(displayAttributeText, attributeMaxChars).take(2)

                        attributeLines.forEachIndexed { index, line ->
                            lp.PrintText(
                                left + 25,
                                attributeY + (index * attributeLineHeight),
                                "0",
                                line,
                                0,
                                attributeFont,
                                attributeFont,
                                1
                            )
                        }
                        attributeY += attributeLines.size * attributeLineHeight
                    }

                    val weightY = attributeY + 10

                    // ---------- GROSS WT ----------
                    lp.PrintText(
                        left + 25,
                        weightY,
                        "0",
                        "Weight : ",
                        0,
                        32,
                        32,
                        1
                    )

                    lp.PrintText(
                        left + 260,
                        weightY,
                        "0",
                        displayWeight,
                        0,
                        32,
                        32,
                        1
                    )

                    // ---------- BARCODE ----------
                    val barcodeHeight = 52
                    val barcodeY = height - 105
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
                    if (teaTimeStamp.isNotEmpty()) {
                        lp.PrintText(
                            right - 255,
                            20,
                            "0",
                            teaTimeStamp,
                            0,
                            26,
                            26,
                            1
                        )
                    }

                    // ---------- PRODUCT ----------
                    val productFont = fitFontSizeForWidth(
                        displayProductName,
                        (right - left - 50).coerceAtLeast(200),
                        45,
                        30
                    )
                    lp.PrintText(
                        left + 25,
                        60,
                        "0",
                        displayProductName,
                        0,
                        productFont,
                        productFont,
                        1
                    )


                // ---------- DESCRIPTION ----------
                val attributeFont = 40
                val attributeY = 120
                val attributeLineHeight = 46
                val attributeMaxChars =
                    (((right - left - 50) * 2.2) / attributeFont).toInt().coerceAtLeast(16)
                val attributeLines =
                    splitByLength(displayAttributeText, attributeMaxChars).take(2)

                attributeLines.forEachIndexed { index, line ->
                    lp.PrintText(
                        left + 25,
                        attributeY + (index * attributeLineHeight),
                        "0",
                        line,
                        0,
                        attributeFont,
                        attributeFont,
                        1
                    )
                }

                val weightY = attributeY + (attributeLines.size * attributeLineHeight) + 14

                // ---------- GROSS WT ----------
                lp.PrintText(
                    left + 25,
                    weightY,
                    "0",
                    "Weight : ",
                    0,
                    40,
                    40,
                    1
                )

                lp.PrintText(
                    left + 260,
                    weightY,
                    "0",
                    displayWeight,
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
    private fun printDryFruitSticker(
        result: MethodChannel.Result,
        width: Int = 600,
        height: Int = 410,
        margin: Int = 0,
        companyName: String = "Majedar Tea Co.",
        productName: String = "",
        attributeLabel: String = "Description",
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
                val teaTimeStamp = if (printTime) {
                    SimpleDateFormat("dd-MM-yyyy HH:mm", Locale.getDefault()).format(Date())
                } else {
                    ""
                }
                val displayProductName = productName.trim()
                val displayDescription = description.trim()
                val displayAttributeLabel = attributeLabel.trim().ifBlank { "Description" }
                val displayAttributeText = if (displayDescription.isBlank()) {
                    displayAttributeLabel
                } else {
                    "$displayAttributeLabel : $displayDescription"
                }
                val displayWeight = grossWt.trim().let {
                    when {
                        it.isEmpty() -> ""
                        it.lowercase(Locale.getDefault()).endsWith("kg") -> it
                        else -> "$it Kg"
                    }
                }
                val printableAttributes = attributes.filter {
                    (it["key"] ?: "").isNotBlank() && (it["value"] ?: "").isNotBlank()
                }.take(4)

//                // ---------- BORDER ----------
//                lp.PrintBox(left, margin, right, height - margin, 3)

                if (teaTimeStamp.isNotEmpty()) {
                    lp.PrintText(
                        right - 255,
                        14,
                        "0",
                        teaTimeStamp,
                        0,
                        22,
                        22,
                        1
                    )
                }

                val productY = if (teaTimeStamp.isNotEmpty()) 42 else 22
                val productFont = fitFontSizeForWidth(
                    displayProductName,
                    (right - left - 50).coerceAtLeast(200),
                    44,
                    34
                )
                lp.PrintText(
                    left + 25,
                    productY,
                    "0",
                    displayProductName,
                    0,
                    productFont,
                    productFont,
                    1
                )

                var attributeY = if (teaTimeStamp.isNotEmpty()) 88 else 72
                if (printableAttributes.isNotEmpty()) {
                    for (item in printableAttributes) {
                        val key = item["key"] ?: ""
                        var value = item["value"] ?: ""

                        if (key.equals("weight", ignoreCase = true)) {
                            value = String.format(Locale.US, "%.3f Kg", value.toDoubleOrNull() ?: 0.0)
                        }

                        val line = "$key : $value"

                        val rowFont = fitFontSizeForWidth(
                            line,
                            (right - left - 50).coerceAtLeast(220),
                            36,
                            28
                        )

                        lp.PrintText(
                            left + 25,
                            attributeY,
                            "0",
                            line,
                            0,
                            rowFont,
                            rowFont,
                            1
                        )

                        attributeY += 42
                    }
                } else {
                    val attributeFont = 30
                    val attributeLineHeight = 32
                    val attributeMaxChars =
                        (((right - left - 50) * 2.2) / attributeFont).toInt().coerceAtLeast(18)
                    val attributeLines =
                        splitByLength(displayAttributeText, attributeMaxChars).take(2)

                    attributeLines.forEachIndexed { index, line ->
                        lp.PrintText(
                            left + 25,
                            attributeY + (index * attributeLineHeight),
                            "0",
                            line,
                            0,
                            attributeFont,
                            attributeFont,
                            1
                        )
                    }
                    attributeY += attributeLines.size * attributeLineHeight
                }

//                val weightY = attributeY + 4
//                lp.PrintText(
//                    left + 25,
//                    weightY,
//                    "0",
//                    "Weight : ",
//                    0,
//                    32,
//                    32,
//                    1
//                )
//
//                lp.PrintText(
//                    left + 170,
//                    weightY,
//                    "0",
//                    displayWeight,
//                    0,
//                    32,
//                    32,
//                    1
//                )

                val barcodeHeight = 80
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
                    4,
                    4
                )

                // ---------- PRINT ----------
                val status = lp.PrintLabel(1, 1)

                mainHandler.post {
                    if (status == 0) {
                        result.success("Dry fruit label printed successfully!")
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

    private fun printNeoLabelSticker(
        result: MethodChannel.Result,
        width: Int = 700,
        height: Int = 600,
        margin: Int = 0,
        companyName: String = "",
        address: String = "",
        phone: String = "",
        email: String = "",
        productName: String = "",
        barcodeData: String = "",
        serialNumber: String = "",
        printSerialNumber: Boolean = false,
        attributes: List<Map<String, String>> = emptyList(),
        layout: Map<String, Any> = emptyMap(),
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

                val left = margin + 20
                val right = width - margin - 20
                val headerLeft = left + 10
                var yPos = margin + 20
                val keyFont = (layout["keyFont"] as? Number)?.toInt() ?: 36
                val valueFont = (layout["valueFont"] as? Number)?.toInt() ?: 40
                val lineHeight = (layout["lineHeight"] as? Number)?.toInt() ?: 36
                val columnGap = (layout["columnGap"] as? Number)?.toInt() ?: 245
                val barcodeHeight = (layout["barcodeHeight"] as? Number)?.toInt() ?: 85
                val bottomPadding = (layout["bottomPadding"] as? Number)?.toInt() ?: 25

                if (!isWhiteLabel) {
                    val companyFont = 40
                    lp.PrintText(
                        headerLeft,
                        yPos,
                        "0",
                        companyName,
                        0,
                        companyFont,
                        companyFont,
                        1
                    )
                    yPos += 52

                    val contactFont = 22
                    for (line in splitByLength(address, 42).take(2)) {
                        lp.PrintText(headerLeft, yPos, "0", line, 0, contactFont, contactFont, 0)
                        yPos += 28
                    }

                    if (phone.isNotBlank()) {
                        lp.PrintText(
                            headerLeft,
                            yPos,
                            "0",
                            "Phone: $phone",
                            0,
                            contactFont,
                            contactFont,
                            0
                        )
                        yPos += 28
                    }

                    if (email.isNotBlank()) {
                        lp.PrintText(
                            headerLeft,
                            yPos,
                            "0",
                            "Email: $email",
                            0,
                            20,
                            20,
                            0
                        )
                        yPos += 32
                    }
                }

                if (printTime) {
                    val dateFormat = SimpleDateFormat("dd-MM-yyyy", Locale.getDefault())
                    val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
                    val dateX = right - 145
                    val dateY = margin + 20

                    lp.PrintText(
                        dateX,
                        dateY,
                        "0",
                        dateFormat.format(Date()),
                        0,
                        20,
                        20,
                        0
                    )
                    lp.PrintText(
                        dateX,
                        dateY + 24,
                        "0",
                        timeFormat.format(Date()),
                        0,
                        20,
                        20,
                        0
                    )
                }

                val printableAttributes = attributes.filter {
                    (it["key"] ?: "").isNotBlank() && (it["value"] ?: "").isNotBlank()
                }.take(3)

                val productLabel = "Product Name :  "
                val productLabelFont = keyFont
                val productValueFont = valueFont
                val productLineHeight = lineHeight + 6
                val productBlockHeight = productLineHeight + 30
                val attrFont = keyFont
                val attrLineHeight = lineHeight
                val productValueX = headerLeft + columnGap

                lp.PrintText(
                    headerLeft,
                    yPos,
                    "0",
                    productLabel,
                    0,
                    productLabelFont,
                    productLabelFont,
                    1
                )

               // for ((index, line) in splitByLength(productName, 18).take(2).withIndex()) {
                    lp.PrintText(
                        productValueX,
                        yPos + 150,
                        "0",
                        productName,
                        0,
                        productValueFont,
                        productValueFont,
                        1
                    )
               // }
                if (printSerialNumber) {
                    yPos += productBlockHeight - 20
                }else{
                    yPos += productBlockHeight
                }

                if (printSerialNumber && serialNumber.isNotBlank()) {
                    val serialText = "Sr No : $serialNumber"
                    lp.PrintText(headerLeft, yPos, "0", serialText, 0, attrFont, attrFont, 0)
                    if(printSerialNumber) {
                        yPos += attrLineHeight + 10
                    }else{
                        yPos += attrLineHeight + 20
                    }
                }

                for (item in printableAttributes) {
                    val key = item["key"] ?: ""
                    val value = item["value"] ?: ""
                    val line = "$key : $value"
                    lp.PrintText(headerLeft, yPos, "0", line, 0, attrFont, attrFont, 0)
                    yPos += attrLineHeight + 20
                }

                val humanReadableHeight = 28
                val barcodeGap = 10
                val bottomSafe = height - margin - bottomPadding
                val barcodeY = bottomSafe - humanReadableHeight - barcodeHeight - barcodeGap
                val availableWidth = (right - left) - 20

                var moduleWidth = 4
                val modulesPerChar = 6

                fun estimateBarcodeWidth(chars: Int, moduleW: Int): Int {
                    return chars * moduleW * modulesPerChar
                }

                var estimatedBarcodeWidth = estimateBarcodeWidth(barcodeData.length, moduleWidth)
                while (estimatedBarcodeWidth > availableWidth && moduleWidth > 1) {
                    moduleWidth -= 1
                    estimatedBarcodeWidth = estimateBarcodeWidth(barcodeData.length, moduleWidth)
                }

                val barcodeX = left + 25
                val barcodeStatus = lp.PrintBarcode1D(
                    barcodeX,
                    barcodeY,
                    1,
                    0,
                    barcodeData,
                    barcodeHeight,
                    1,
                    moduleWidth,
                    moduleWidth
                )

                if (barcodeStatus != 0) {
                    mainHandler.post {
                        result.error("BARCODE_ERROR", "Failed: $barcodeStatus", null)
                    }
                    return@Thread
                }

                val status = lp.PrintLabel(1, 1)

                mainHandler.post {
                    if (status == 0) {
                        result.success("Neo label printed successfully!")
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

    private fun printSmallSevenLabelSticker(
        result: MethodChannel.Result,
        width: Int = 600,
        height: Int = 410,
        margin: Int = 0,
        companyName: String = "",
        address: String = "",
        phone: String = "",
        email: String = "",
        productName: String = "",
        barcodeData: String = "",
        serialNumber: String = "",
        printSerialNumber: Boolean = false,
        attributes: List<Map<String, String>> = emptyList(),
        layout: Map<String, Any> = emptyMap(),
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

                val left = margin + 20
                val right = width - margin - 20
                val headerLeft = left + 10
                var yPos = margin + 20
                val keyFont = (layout["keyFont"] as? Number)?.toInt() ?: 36
                val valueFont = (layout["valueFont"] as? Number)?.toInt() ?: 40
                val lineHeight = (layout["lineHeight"] as? Number)?.toInt() ?: 36
                val columnGap = (layout["columnGap"] as? Number)?.toInt() ?: 245
                val barcodeHeight = (layout["barcodeHeight"] as? Number)?.toInt() ?: 85
                val bottomPadding = (layout["bottomPadding"] as? Number)?.toInt() ?: 25

                if (!isWhiteLabel) {
                    val companyText = companyName.trim()
                    if (companyText.isNotEmpty()) {
                        val reservedRightSpace = if (printTime) 155 else 0
                        val maxCompanyWidth =
                            (right - headerLeft - reservedRightSpace).coerceAtLeast(180)
                        val companyFont = fitFontSizeForWidth(
                            text = companyText,
                            maxWidth = maxCompanyWidth,
                            preferredFont = 40,
                            minFont = 20
                        )

                        lp.PrintText(
                            headerLeft,
                            yPos,
                            "0",
                            companyText,
                            0,
                            companyFont,
                            companyFont,
                            1
                        )
                        yPos += maxOf(companyFont + 12, 36)
                    }

//                    val contactFont = 22
//                    for (line in splitByLength(address, 42).take(2)) {
//                        lp.PrintText(headerLeft, yPos, "0", line, 0, contactFont, contactFont, 0)
//                        yPos += 28
//                    }

//                    if (phone.isNotBlank()) {
//                        lp.PrintText(
//                            headerLeft,
//                            yPos,
//                            "0",
//                            "Phone: $phone",
//                            0,
//                            contactFont,
//                            contactFont,
//                            0
//                        )
//                        yPos += 28
//                    }

//                    if (email.isNotBlank()) {
//                        lp.PrintText(
//                            headerLeft,
//                            yPos,
//                            "0",
//                            "Email: $email",
//                            0,
//                            20,
//                            20,
//                            0
//                        )
//                        yPos += 32
//                    }
                }

                val printableAttributes = attributes.filter {
                    (it["key"] ?: "").isNotBlank() && (it["value"] ?: "").isNotBlank()
                }.take(10)

                val productValueFont = valueFont
                val productLineHeight = lineHeight + 6
                val productBlockHeight = productLineHeight
                val productValueX = headerLeft
                val dateFormat = SimpleDateFormat("dd-MM-yyyy", Locale.getDefault())
                val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
                val productDateX = right - 145
                val productDateY = yPos
                val productNameMaxChars = if (printTime) 25 else 28

                for ((index, line) in splitByLength(productName, productNameMaxChars).take(2).withIndex()) {
                    lp.PrintText(
                        productValueX,
                        yPos + (index * productLineHeight),
                        "0",
                        line,
                        0,
                        productValueFont,
                        productValueFont,
                        1
                    )
                }

                if (printTime) {
                    lp.PrintText(
                        productDateX,
                        productDateY,
                        "0",
                        dateFormat.format(Date()),
                        0,
                        20,
                        20,
                        0
                    )
                    lp.PrintText(
                        productDateX,
                        productDateY + 24,
                        "0",
                        timeFormat.format(Date()),
                        0,
                        20,
                        20,
                        0
                    )
                }

                yPos += if (printSerialNumber) productBlockHeight - 20 else productBlockHeight

                if (printSerialNumber && serialNumber.isNotBlank()) {
                    val serialText = "Sr No : $serialNumber"
                    lp.PrintText(headerLeft, yPos, "0", serialText, 0, 20, 20, 0)
                    yPos += 32
                }

                if (printableAttributes.isNotEmpty()) {
                    val attrFont = minOf(keyFont, valueFont, 27)
                    val attrLineHeight = maxOf(attrFont + 6, 27)
                    val columnSpacing = 20
                    val col1X = left + 10
                    val totalPrintableWidth = (right - col1X).coerceAtLeast(200)
                    val columnWidth = ((totalPrintableWidth - columnSpacing) / 2).coerceAtLeast(150)
                    val col2X = col1X + columnWidth + columnSpacing
                    val approxCharsPerLine = ((columnWidth * 2.2) / attrFont).toInt().coerceAtLeast(10)

                    fun wrapAttributeText(text: String, maxChars: Int): List<String> {
                        if (text.isBlank()) return emptyList()

                        val words = text.trim().split(Regex("\\s+"))
                        val lines = mutableListOf<String>()
                        var current = ""

                        for (word in words) {
                            if (word.length > maxChars) {
                                if (current.isNotBlank()) {
                                    lines.add(current)
                                    current = ""
                                }
                                lines.addAll(splitByLength(word, maxChars))
                                continue
                            }

                            val candidate = if (current.isBlank()) word else "$current $word"
                            if (candidate.length <= maxChars) {
                                current = candidate
                            } else {
                                if (current.isNotBlank()) {
                                    lines.add(current)
                                }
                                current = word
                            }
                        }

                        if (current.isNotBlank()) {
                            lines.add(current)
                        }

                        return lines
                    }

                    for (i in printableAttributes.indices step 2) {
                        if (yPos > height - margin - bottomPadding) break

                        val first = printableAttributes[i]
                        val second = printableAttributes.getOrNull(i + 1)

                        val firstText =
                            "${first["key"] ?: ""} : ${first["value"] ?: ""}".trim()
                        val firstLines = wrapAttributeText(firstText, approxCharsPerLine)
                        firstLines.forEachIndexed { lineIndex, line ->
                            lp.PrintText(
                                col1X,
                                yPos + (lineIndex * attrLineHeight),
                                "0",
                                line,
                                0,
                                attrFont,
                                attrFont,
                                0
                            )
                        }

                        if (second != null) {
                            val secondText =
                                "${second["key"] ?: ""} : ${second["value"] ?: ""}".trim()
                            val secondLines = wrapAttributeText(secondText, approxCharsPerLine)
                            secondLines.forEachIndexed { lineIndex, line ->
                                lp.PrintText(
                                    col2X,
                                    yPos + (lineIndex * attrLineHeight),
                                    "0",
                                    line,
                                    0,
                                    attrFont,
                                    attrFont,
                                    0
                                )
                            }

                            val rowLines = maxOf(firstLines.size, secondLines.size).coerceAtLeast(1)
                            yPos += rowLines * attrLineHeight
                        } else {
                            val rowLines = firstLines.size.coerceAtLeast(1)
                            yPos += rowLines * attrLineHeight
                        }
                    }
                }

                val humanReadableHeight = 28
                val barcodeGap = 10
                val bottomSafe = height - margin - bottomPadding
                val barcodeY = bottomSafe - humanReadableHeight - barcodeHeight - barcodeGap
                val availableWidth = (right - left) - 20

                var moduleWidth = 4
                val modulesPerChar = 6

                fun estimateBarcodeWidth(chars: Int, moduleW: Int): Int {
                    return chars * moduleW * modulesPerChar
                }

                var estimatedBarcodeWidth = estimateBarcodeWidth(barcodeData.length, moduleWidth)
                while (estimatedBarcodeWidth > availableWidth && moduleWidth > 1) {
                    moduleWidth -= 1
                    estimatedBarcodeWidth = estimateBarcodeWidth(barcodeData.length, moduleWidth)
                }

                val barcodeX = left + 25
                val barcodeStatus = lp.PrintBarcode1D(
                    barcodeX,
                    barcodeY,
                    1,
                    0,
                    barcodeData,
                    barcodeHeight,
                    1,
                    moduleWidth,
                    moduleWidth
                )

                if (barcodeStatus != 0) {
                    mainHandler.post {
                        result.error("BARCODE_ERROR", "Failed: $barcodeStatus", null)
                    }
                    return@Thread
                }

                val status = lp.PrintLabel(1, 1)

                mainHandler.post {
                    if (status == 0) {
                        result.success("Small seven label printed successfully!")
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
