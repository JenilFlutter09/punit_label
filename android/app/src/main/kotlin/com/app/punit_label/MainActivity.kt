package com.app.punit_label
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
                    "printOneSticker" -> printOneSticker(result)
                    "getPrinterStatus" -> getPrinterStatus(result)
                    // New: Test sticker with custom size
                    "printTestSticker" -> {
                        val args = call.arguments as? Map<String, Any> ?: emptyMap()

                        val width = (args["width"] as? Number)?.toInt() ?: 700
                        val height = (args["height"] as? Number)?.toInt() ?: 623
                        val margin = (args["margin"] as? Number)?.toInt() ?: 20
                        val thickness = (args["thickness"] as? Number)?.toInt() ?: 8
                        val isGrid = args["isGrid"] as? Boolean ?: false
                        val companyName = args["companyName"]?.toString() ?: ""
                        val companyContact = args["companyContact"]?.toString() ?: ""
                        val barcodeData = args["barcodeData"]?.toString() ?: ""
                        val productName = args["productName"]?.toString() ?: ""
                        val rawAttributes = call.argument<List<Map<String, Any>>>("attributes") ?: emptyList()
                        val attributes = rawAttributes.map { it.mapValues { v -> v.value.toString() } }
                        printTrySticker(
                            result = result,
                            width = width,
                            height = height,
                            margin = margin,
                            thickness = thickness,
                            isGrid = isGrid,
                            companyName = companyName,
                            companyContact = companyContact,
                            barcodeData = barcodeData,
                            productName = productName,
                            attributes = attributes
                        )
                    }
                    "printNewSticker" -> {
                        val args = call.arguments as? Map<String, String> ?: emptyMap()
                        val date = args["date"] ?: ""
                        val spoolno = args["spoolno"] ?: ""
                        val dpcsize = args["dpcsize"] ?: ""
                        val gross = args["gross"] ?: ""
                        val tare = args["tare"] ?: ""
                        val net = args["net"] ?: ""
                        val barcode = args["barcode"] ?: ""
                        printNewSticker(date,spoolno,dpcsize,gross,tare,net,barcode,result)
                    }
                    "printSticker" -> {
                        val args = call.arguments as? Map<String, String> ?: emptyMap()
                        val orderNo = args["orderNo"] ?: ""
                        val productNo = args["productNo"] ?: ""
                        val productType = args["productType"] ?: ""
                        val barcodeData = args["barcodeData"] ?: ""
                        val productQuality = args["productQuality"] ?: ""
                        val gsm = args["gsm"] ?: ""
                        val rollSize = args["rollSize"] ?: ""
                        val color = args["color"] ?: ""
                        val grossWeight = args["grossWeight"] ?: ""
                        val netWeight = args["netWeight"] ?: ""
                        printRollSticker(orderNo, productNo, productType, barcodeData,productQuality,gsm,rollSize,color,grossWeight,netWeight,result)
                    }
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

    private fun printNewSticker(
        date: String,
        spoolNo: String,
        dpcSize: String,
        gross: String,
        tare: String,
        net: String,
        barcode: String,
        result: MethodChannel.Result
    ) {
        Thread {
            try {
                val lp = printer ?: run {
                    mainHandler.post { result.error("NO_PRINTER", "Printer not connected", null) }
                    return@Thread
                }

                // ===== LABEL SIZE =====
                val labelWidth = 700
                val labelHeight = 623
                val setSize = lp.SetLabelSize(labelWidth, labelHeight)
                if (setSize != 0) {
                    mainHandler.post { result.error("SET_LABEL_ERROR", "Failed: $setSize", null) }
                    return@Thread
                }

                lp.SetPrintDensity(15)

                // ===== COMMON SPACING =====
                var currentY = 40
                val lineSpace = 55

                // ===== 1️⃣ COMPANY NAME (CENTER) =====
                val companyName = "Hi - Energy Wires"
                val companyFont = 48
                lp.PrintText(
                    centerText(companyName, companyFont, labelWidth),
                    currentY,
                    "0", companyName, 0,
                    companyFont, companyFont, 0
                )
                currentY += lineSpace + 10

                // ===== 2️⃣ CONTACT LINE (CENTER) =====
                val contact = "KIADB Industrial Area, Vemgal  Ph: 9448664666 / 7353018845"
                val contactFont = 26
                lp.PrintText(
                    centerText(contact, contactFont, labelWidth),
                    currentY,
                    "0", contact, 0,
                    contactFont, contactFont, 0
                )
                currentY += lineSpace

                // ===== 3️⃣ DATE + SPOOL (CENTER) =====
                val ds = "Date: $date    Spool No: $spoolNo"
                val dsFont = 30
                lp.PrintText(
                    centerText(ds, dsFont, labelWidth),
                    currentY,
                    "0", ds, 0,
                    dsFont, dsFont, 0
                )
                currentY += lineSpace

                // ===== 4️⃣ DPC SIZE (CENTER) =====
                val dpcLine = "DPC Size: $dpcSize"
                val dpcFont = 34
                lp.PrintText(
                    centerText(dpcLine, dpcFont, labelWidth),
                    currentY,
                    "0", dpcLine, 0,
                    dpcFont, dpcFont, 0
                )
                currentY += lineSpace

                // ===== 5️⃣ GROSS WEIGHT (CENTER) =====
                val grossLine = "Gross Weight: $gross KG"
                lp.PrintText(
                    centerText(grossLine, dpcFont, labelWidth),
                    currentY,
                    "0", grossLine, 0,
                    dpcFont, dpcFont, 0
                )
                currentY += lineSpace

                // ===== 6️⃣ TARE WEIGHT (CENTER) =====
                val tareLine = "Tare Weight: $tare KG"
                lp.PrintText(
                    centerText(tareLine, dpcFont, labelWidth),
                    currentY,
                    "0", tareLine, 0,
                    dpcFont, dpcFont, 0
                )
                currentY += lineSpace

                // ===== 7️⃣ NET WEIGHT (CENTER) =====
                val netLine = "Net Weight: $net KG"
                lp.PrintText(
                    centerText(netLine, dpcFont, labelWidth),
                    currentY,
                    "0", netLine, 0,
                    dpcFont, dpcFont, 0
                )
                currentY += lineSpace + 10
// ===== 🧾 BARCODE (CENTERED) =====
                val barcodeHeight = 80
                val barcodeData = barcode
// Estimate barcode width for center alignment
// (20px per char is a safe average for 1D Code128)
                val rectBottom = labelHeight
                val estimatedBarcodeWidth = barcodeData.length * 20

                val barcodeX = (labelWidth - estimatedBarcodeWidth) / 4
                val barcodeY = rectBottom - barcodeHeight - 80  // 40px above footer

                val barcodeStatus = lp.PrintBarcode1D(
                    barcodeX,
                    barcodeY,
                    1,              // Code128
                    0,              // Rotate
                    barcodeData,    // Data
                    barcodeHeight,  // Height
                    0,              // Human readable font
                    4,              // Narrow bar width
                    4               // Wide bar width
                )

                if (barcodeStatus != 0) {
                    mainHandler.post { result.error("BARCODE_ERROR", "Failed: $barcodeStatus", null) }
                    return@Thread
                }

// ===== 🦶 FOOTER (CENTERED) =====
                val footerText = "Label generated from weighing erp by punitinstrument.com"
                val footerFontSize = 22

// estimate width
                val estimatedFooterWidth = (footerText.length * footerFontSize) / 2.2
                val footerX = ((labelWidth - estimatedFooterWidth) / 2).toInt()

// Place footer 15px above bottom edge
                val footerY = rectBottom - 45

                lp.PrintText(
                    footerX,
                    footerY,
                    "0",
                    footerText,
                    0,
                    footerFontSize,
                    footerFontSize,
                    0
                )

                //===== PRINT =====
                val execStatus = lp.PrintLabel(1, 2)
                mainHandler.post {
                    if (execStatus == 0) {
                        result.success("✅ Sticker printed successfully!")
                    } else {
                        result.error("PRINT_EXEC_ERROR", "Failed to execute: $execStatus", null)
                    }
                }

            } catch (e: Exception) {
                mainHandler.post { result.error("PRINT_ERROR", e.message ?: "Unknown error", null) }
            }
        }.start()
    }

    // ===== Center Helper =====
    private fun centerText(text: String, fontSize: Int, labelWidth: Int): Int {
        val estWidth = text.length * fontSize / 2.2
        return ((labelWidth - estWidth) / 2).toInt()
    }


    private fun printRollSticker(
        orderNo: String,
        productNo: String,
        productType: String,
        barcodeData: String,
        productQuality: String,
        gsm: String,
        rollSize: String,
        color: String,
        grossWeight: String,
        netWeight: String,
        result: MethodChannel.Result
    ) {
        Thread {
            try {
                val lp = printer ?: run {
                    mainHandler.post { result.error("NO_PRINTER", "Printer not connected", null) }
                    return@Thread
                }

                val labelWidth = 700
                val labelHeight = 623
                val setSize = lp.SetLabelSize(labelWidth, labelHeight)
                if (setSize != 0) {
                    mainHandler.post { result.error("SET_LABEL_ERROR", "Failed: $setSize", null) }
                    return@Thread
                }

                lp.SetPrintDensity(15)

                // ===== 📦 PRODUCT TABLE =====
                val rectInset = 0
                val rectTop = 20
                val rectBottom = labelHeight - 50
                val borderThickness = 5
                lp.PrintRectangle(rectInset, rectTop, labelWidth - rectInset, rectBottom, borderThickness)


                // ===== 🏢 COMPANY INFO (No Logo) =====
                val companyName = "NIVA GROUP INDIA"
                val companyFontSize = 44

                // Center the title horizontally
                //  val companyX = (labelWidth / 2) - (companyName.length * companyFontSize / 4) // Approx centering
                val estimatedTextWidth = companyName.length * companyFontSize / 2.2
                val companyX = (labelWidth - estimatedTextWidth) / 2
                val companyY = rectTop + 30
                lp.PrintText(companyX.toInt(), companyY, "0", companyName, 0, companyFontSize, companyFontSize, 0)

                val contactText = "TEL: +91-7573830094  |  WWW.NIVAGROUPINDIA.COM"
                val contactFontSize = 24
                val contactX = (labelWidth / 2) - (contactText.length * contactFontSize / 4) // Center contact text
                lp.PrintText(contactX, companyY + 55, "0", contactText, 0, contactFontSize, contactFontSize, 0)


                val contentLeft = rectInset + 15
                val contentRight = labelWidth - rectInset - 15
                val contentTop = rectTop + 15
                val contentBottom = rectBottom - 15

                val tableTop = companyY + 55 + 25
                val tableBottom = contentBottom - 100
                val tableWidth = contentRight - contentLeft
                val colDividerX = contentLeft + (tableWidth / 2)

                val rowHeights = listOf(60, 75, 60, 60, 60)
                var currentY = tableTop
                val rowYPositions = mutableListOf<Int>()
                for (height in rowHeights) {
                    lp.PrintLine(contentLeft, currentY + 5, contentRight, currentY + 5, 2)
                    rowYPositions.add(currentY + 5)
                    currentY += height
                }
                val finalBottomY = currentY + 5
                lp.PrintLine(contentLeft, finalBottomY, contentRight, finalBottomY, 2)
                rowYPositions.add(finalBottomY)
                for (i in listOf(0, 2, 3, 4)) {
                    val top = rowYPositions[i] + 5
                    val bottom = rowYPositions[i + 1] - 5
                    lp.PrintLine(colDividerX, top, colDividerX, bottom, 2)
                }

                val titleFont = 30
                val valueFont = 32
                val bigFont = 38

                lp.PrintText(contentLeft + 20, rowYPositions[0] + 35, "0", "Sr No:", 0, titleFont, titleFont, 0)
                lp.PrintText(contentLeft + 150, rowYPositions[0] + 35, "0", productNo, 0, valueFont, valueFont, 0)

                lp.PrintText(colDividerX + 20, rowYPositions[0] + 35, "0", "Order No:", 0, titleFont, titleFont, 0)
                lp.PrintText(colDividerX + 190, rowYPositions[0] + 35, "0", orderNo, 0, valueFont, valueFont, 0)

                lp.PrintText(contentLeft + 20, rowYPositions[1] + 40, "0", "Quality:", 0, titleFont, titleFont, 0)
                lp.PrintText(contentLeft + 180, rowYPositions[1] + 40, "0", productQuality, 0, valueFont, valueFont, 0)

                lp.PrintText(contentLeft + 20, rowYPositions[2] + 35, "0", "Color:", 0, titleFont, titleFont, 0)
                lp.PrintText(contentLeft + 130, rowYPositions[2] + 35, "0", color, 0, valueFont, valueFont, 0)

                lp.PrintText(colDividerX + 20, rowYPositions[2] + 35, "0", "GSM:", 0, titleFont, titleFont, 0)
                lp.PrintText(colDividerX + 120, rowYPositions[2] + 35, "0", gsm, 0, valueFont, valueFont, 0)

                lp.PrintText(contentLeft + 20, rowYPositions[3] + 35, "0", "Roll Size:", 0, titleFont, titleFont, 0)
                lp.PrintText(contentLeft + 180, rowYPositions[3] + 35, "0", rollSize, 0, valueFont, valueFont, 0)

                lp.PrintText(colDividerX + 20, rowYPositions[3] + 35, "0", "MTR:", 0, titleFont, titleFont, 0)
                lp.PrintText(colDividerX + 130, rowYPositions[3] + 35, "0", productType, 0, valueFont, valueFont, 0)

                lp.PrintText(contentLeft + 20, rowYPositions[4] + 35, "0", "Gross :", 0, titleFont, titleFont, 0)
                lp.PrintText(contentLeft + 150, rowYPositions[4] + 35, "0", "$grossWeight KG", 0, valueFont, valueFont, 0)

                lp.PrintText(colDividerX + 30, rowYPositions[4] + 35, "0", "Net :", 0, titleFont, titleFont, 0)
                lp.PrintText(colDividerX + 120, rowYPositions[4] + 35, "0", "$netWeight KG", 0, valueFont, valueFont, 0)

                //            lp.PrintText(contentLeft + 20, rowYPositions[4] + 40, "0", "Net Weight:", 0, titleFont, titleFont, 0)
                //            lp.PrintText(contentLeft + 250, rowYPositions[4] + 40, "0", "$netWeight KG", 0, bigFont, bigFont, 0)

                // ===== 🧾 BARCODE =====
                val barcodeHeight = 80
                val barcodeX = (labelWidth / 2) - 180
                val barcodeY = rectBottom - barcodeHeight - 20
                val barcodeStatus = lp.PrintBarcode1D(
                    barcodeX,
                    barcodeY,
                    1, 0, barcodeData,
                    barcodeHeight, 0, 4, 4
                )
                if (barcodeStatus != 0) {
                    mainHandler.post { result.error("BARCODE_ERROR", "Failed: $barcodeStatus", null) }
                    return@Thread
                }
                val footerText = "Label generated from weighing erp by punitinstrument.com"
                val footerFontSize = 22
                val footerY = rectBottom - 10  // slightly above bottom edge
                val footerX = (labelWidth / 2) - (footerText.length * footerFontSize / 4)
                lp.PrintText(footerX, footerY, "0", footerText, 0, footerFontSize, footerFontSize, 0)

                val execStatus = lp.PrintLabel(1, 2)
                mainHandler.post {
                    if (execStatus == 0) {
                        result.success("✅ Sticker printed successfully!")
                    } else {
                        result.error("PRINT_EXEC_ERROR", "Failed to execute: $execStatus", null)
                    }
                }

            } catch (e: Exception) {
                mainHandler.post { result.error("PRINT_ERROR", e.message ?: "Unknown error", null) }
            }
        }.start()
    }

    private fun printOneSticker(
        result: MethodChannel.Result
    ) {
        Thread {
            try {
                val lp = printer ?: run {
                    mainHandler.post { result.error("NO_PRINTER", "Printer not connected", null) }
                    return@Thread
                }

                val labelWidth = 700
                val labelHeight = 623
                val setSize = lp.SetLabelSize(labelWidth, labelHeight)
                if (setSize != 0) {
                    mainHandler.post { result.error("SET_LABEL_ERROR", "Failed: $setSize", null) }
                    return@Thread
                }

                lp.SetPrintDensity(15)

                // ===== 📦 PRODUCT TABLE =====
                val rectInset = 0
                val rectTop = 20
                val rectBottom = labelHeight - 50
                val borderThickness = 5
                lp.PrintRectangle(rectInset, rectTop, labelWidth - rectInset, rectBottom, borderThickness)
                val execStatus = lp.PrintLabel(1, 2)
                mainHandler.post {
                    if (execStatus == 0) {
                        result.success("✅ Sticker printed successfully!")
                    } else {
                        result.error("PRINT_EXEC_ERROR", "Failed to execute: $execStatus", null)
                    }
                }

            } catch (e: Exception) {
                mainHandler.post { result.error("PRINT_ERROR", e.message ?: "Unknown error", null) }
            }
        }.start()
    }
    private fun printTrySticker(
        result: MethodChannel.Result,
        width: Int = 700,
        height: Int = 623,
        margin: Int = 30,
        thickness: Int = 8,
        isGrid: Boolean = false,
        attributes: List<Map<String, String>> = emptyList(),
        companyName: String = "NIVA GROUP INDIA",
        companyContact: String = "TEL: +91-7573830094  |  WWW.NIVAGROUPINDIA.COM",
        barcodeData: String = "123456789012",
        productName: String = "123456789012"
    )   {
        Thread {
            try {

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
                val left = margin
                val top = margin
                val right = width - margin
                val bottom = height - margin
                val titleFont = 40
                val contactFont = 26

                val companyX = (width / 2) - (companyName.length * titleFont / 4)
                val companyY = top + 20
                lp.PrintText(companyX, companyY, "0", companyName, 0, titleFont, titleFont, 0)

                val contactX = (width / 2) - (companyContact.length * contactFont / 4)
                lp.PrintText(
                    contactX,
                    companyY + 55,
                    "0",
                    companyContact,
                    0,
                    contactFont,
                    contactFont,
                    0
                )
                // --- after contact printing, define centers & bounds ---
                val cx = width / 2
                val cy = height / 2

                var yPos = companyY + 100
                val lineHeight = 60

                // helper to estimate text pixel width (simple approximation)
                fun estimateTextWidth(text: String, fontSize: Int): Int {
                    // average char width ≈ 0.5 * fontSize (approximation; tweak if needed)
                    return (text.length * fontSize * 0.5).toInt()
                }
                // --- PRODUCT NAME ---
                val productFont = 34

                //val productX = isGrid ? (width / 2) - (productName.length * productFont / 4) : left + 20
                val productX = left + 20
                val productY = yPos

                lp.PrintText(productX, productY, "0", productName, 0, productFont, productFont, 0)

// update yPos to start attributes below product name
                yPos = productY + 60


// Print attributes (unchanged logic, but uses cx for better alignment)
                if (attributes.isNotEmpty()) {
                    if (!isGrid) {
                        for (item in attributes) {
                            if (yPos > bottom - 150) break

                            val key = item["key"] ?: ""
                            val value = item["value"] ?: ""

                            // left column offset relative to center
                            val keyX = left + 20
                            val valX = keyX + 200

                            lp.PrintText(keyX, yPos, "0", "$key:", 0, 30, 30, 0)
                            lp.PrintText(valX, yPos, "0", value, 0, 34, 34, 0)

                            yPos += lineHeight
                        }
                    } else {
                        val col1X = left + 20
                        val col2X = width / 2 + 20

                        for (i in attributes.indices step 2) {
                            if (yPos > bottom - 150) break

                            val first = attributes[i]
                            val second = attributes.getOrNull(i + 1)

                            lp.PrintText(col1X, yPos, "0", "${first["key"]}:", 0, 30, 30, 0)
                            lp.PrintText(col1X + 180, yPos, "0", first["value"] ?: "", 0, 34, 34, 0)

                            if (second != null) {
                                lp.PrintText(col2X, yPos, "0", "${second["key"]}:", 0, 30, 30, 0)
                                lp.PrintText(
                                    col2X + 180,
                                    yPos,
                                    "0",
                                    second["value"] ?: "",
                                    0,
                                    34,
                                    34,
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
                val barcodeHeight = 80
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
                var barcodeX = left + 10 + ((availableWidth - estimatedBarcodeWidth) / 4)

// safety clamps so the X is legal
                if (barcodeX < left + 5) barcodeX = left + 5
                if (barcodeX + estimatedBarcodeWidth > right - 5) barcodeX =
                    right - estimatedBarcodeWidth - 5

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

// place footer below barcode by 10 px if space permits, otherwise above it

//                val footerBelowY = barcodeY + barcodeHeight + 10
//                val footerAboveY = barcodeY - 20
//                val footerY = when {
//                    footerBelowY <= bottom - 5 -> footerBelowY
//                    footerAboveY >= top + 5 -> footerAboveY
//                    else -> (bottom - 10) // fallback inside bounds
//                }


                lp.PrintText(footerX, footerY, "0", footerText, 0, footerFont, footerFont, 0)

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
/*// ================================================
              // ATTRIBUTES
              // ================================================
              var yPos = companyY + 110
              val lineHeight = 60

              if (attributes.isNotEmpty()) {
                  for (item in attributes) {

                      if (yPos > bottom - 150) break

                      val key = item["key"] ?: ""
                      val value = item["value"] ?: ""

                      lp.PrintText(cx - 240, yPos, "0", "$key:", 0, 30, 30, 0)
                      lp.PrintText(cx - 20, yPos, "0", value, 0, 34, 34, 0)

                      yPos += lineHeight
                  }
              } else {
                  lp.PrintText((width / 2) - 180, 220, "0", "TEST STICKER", 0, 40, 40, 1)
                  lp.PrintText((width / 2) - 200, 290, "0", "Size: ${width}×${height}", 0, 30, 30, 0)
                  lp.PrintText((width / 2) - 200, 350, "0", "Printer Connected ✔", 0, 30, 30, 0)
              }*/
// ================================================
// ATTRIBUTES (NORMAL or GRID)
// ================================================