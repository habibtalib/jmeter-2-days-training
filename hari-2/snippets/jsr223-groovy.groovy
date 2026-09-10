// =====================================================================
//  Contoh skrip JSR223 (Groovy) untuk JMeter — Hari 2
//  Groovy ialah bahasa skrip yang DISYORKAN dalam JMeter (paling laju,
//  ada caching). Elakkan BeanShell untuk beban tinggi.
//  Letak kod ini dalam: JSR223 Sampler / JSR223 PreProcessor / PostProcessor.
//  PENTING: pilih Language = "groovy" dan (untuk beban) tandai "Cache
//  compiled script if available".
// =====================================================================

// ---------------------------------------------------------------------
// 1) JSR223 PreProcessor — jana data unik sebelum permintaan
//    (letak sebagai anak sampler "bayar-cukai")
// ---------------------------------------------------------------------
// No. rujukan pelanggan unik untuk setiap permintaan
vars.put("no_rujukan", "REF-" + System.currentTimeMillis() + "-" + Thread.currentThread().getId())

// Pilih tempoh cukai secara rawak: 6 atau 12 bulan
def tempoh = (Math.random() < 0.5) ? 6 : 12
vars.put("tempoh_bulan", tempoh.toString())

log.info("Menyediakan bayaran: rujukan=" + vars.get("no_rujukan") + " tempoh=" + tempoh)


// ---------------------------------------------------------------------
// 2) JSR223 PostProcessor — sahkan respons JSON secara terperinci
//    (letak sebagai anak sampler "log-masuk"); tandakan gagal jika perlu
// ---------------------------------------------------------------------
import groovy.json.JsonSlurper

def kod = prev.getResponseCode()          // 'prev' = SampleResult sampler sebelum ini
if (kod == "200") {
    def json = new JsonSlurper().parseText(prev.getResponseDataAsString())
    if (!json.token) {
        prev.setSuccessful(false)
        prev.setResponseMessage("Log masuk 200 tetapi tiada token dalam respons")
    } else {
        // simpan panjang token sebagai contoh metrik tersuai
        vars.put("panjang_token", json.token.length().toString())
    }
} else {
    prev.setSuccessful(false)
    prev.setResponseMessage("Log masuk mengembalikan kod " + kod)
}


// ---------------------------------------------------------------------
// 3) JSR223 Sampler — sampler tersuai penuh (jika perlu logik tempatan)
//    'SampleResult' tersedia untuk mengawal masa & status sampel.
// ---------------------------------------------------------------------
SampleResult.setSampleLabel("Pengiraan tempatan")
SampleResult.sampleStart()
def jumlah = 0
(1..1000).each { jumlah += it }
SampleResult.setResponseData("Jumlah 1..1000 = " + jumlah, "UTF-8")
SampleResult.setSuccessful(true)
SampleResult.sampleEnd()


// ---------------------------------------------------------------------
//  Objek terbina yang biasa digunakan dalam JSR223:
//    vars         -> JMeterVariables  (vars.get("x") / vars.put("x", v))
//    props        -> sifat global JMeter (props.get / props.put)
//    prev         -> SampleResult sampler sebelumnya
//    ctx          -> JMeterContext (thread semasa, dsb.)
//    log          -> pengelog (log.info / log.warn / log.error)
//    SampleResult -> hanya dalam JSR223 Sampler
//    sampler      -> sampler semasa (dalam PreProcessor)
// ---------------------------------------------------------------------
