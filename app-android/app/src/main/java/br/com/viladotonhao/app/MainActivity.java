package br.com.viladotonhao.app;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.webkit.CookieManager;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.PendingPurchasesParams;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryPurchasesParams;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Vila do Tonhão: o jogo (viladotonhao.com.br) roda dentro deste app, sem navegador e sem barra.
 * As compras usam o Google Play Billing; o servidor do jogo confere cada compra no Google antes de entregar.
 */
public class MainActivity extends Activity implements PurchasesUpdatedListener {
    private static final String SITE = "https://viladotonhao.com.br/?app=1";
    private static final String HOST = "viladotonhao.com.br";
    private WebView web;
    private BillingClient billing;
    private final Map<String, ProductDetails> produtos = new HashMap<>();
    private ValueCallback<Uri[]> escolhaArquivo;
    private static final int PEDIR_ARQUIVO = 42;

    @SuppressLint({"SetJavaScriptEnabled", "AddJavascriptInterface"})
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Window w = getWindow();
        w.setStatusBarColor(Color.parseColor("#2B1A20"));
        w.setNavigationBarColor(Color.parseColor("#2B1A20"));
        telaCheia();

        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#2B1A20"));
        setContentView(web);

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setLoadWithOverviewMode(true);
        s.setUseWideViewPort(true);
        s.setTextZoom(100);
        s.setUserAgentString(s.getUserAgentString() + " VilaDoTonhaoApp/" + BuildConfig.VERSION_NAME);
        CookieManager.getInstance().setAcceptCookie(true);
        CookieManager.getInstance().setAcceptThirdPartyCookies(web, true);

        web.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest req) {
                Uri u = req.getUrl();
                String h = u.getHost() == null ? "" : u.getHost();
                if (h.equals(HOST) || h.endsWith(".supabase.co") || h.endsWith(".workers.dev")) return false;
                // links de fora (Instagram, WhatsApp, e-mail...) abrem no app certo do celular
                try { startActivity(new Intent(Intent.ACTION_VIEW, u)); } catch (Exception e) { }
                return true;
            }
        });
        web.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onShowFileChooser(WebView v, ValueCallback<Uri[]> cb, FileChooserParams p) {
                if (escolhaArquivo != null) escolhaArquivo.onReceiveValue(null);
                escolhaArquivo = cb;
                try { startActivityForResult(p.createIntent(), PEDIR_ARQUIVO); } catch (Exception e) { escolhaArquivo = null; return false; }
                return true;
            }
        });
        web.addJavascriptInterface(new Ponte(), "AndroidPlay");

        billing = BillingClient.newBuilder(this)
                .setListener(this)
                .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
                .build();
        conectarBilling(null);

        Uri link = getIntent() != null ? getIntent().getData() : null;
        if (savedInstanceState != null) web.restoreState(savedInstanceState);
        else web.loadUrl(link != null && HOST.equals(link.getHost()) ? link.toString() : SITE);
    }

    private void telaCheia() {
        if (Build.VERSION.SDK_INT >= 30) {
            WindowInsetsController c = getWindow().getInsetsController();
            if (c != null) {
                c.hide(WindowInsets.Type.statusBars() | WindowInsets.Type.navigationBars());
                c.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
        }
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) telaCheia();
    }

    @Override
    protected void onSaveInstanceState(Bundle out) { super.onSaveInstanceState(out); web.saveState(out); }

    @Override
    protected void onResume() { super.onResume(); web.onResume(); }

    @Override
    protected void onPause() { web.onPause(); super.onPause(); }

    @Override
    protected void onDestroy() {
        if (billing != null) billing.endConnection();
        web.destroy();
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        if (web.canGoBack()) web.goBack(); else super.onBackPressed();
    }

    @Override
    protected void onActivityResult(int req, int res, Intent data) {
        super.onActivityResult(req, res, data);
        if (req == PEDIR_ARQUIVO && escolhaArquivo != null) {
            escolhaArquivo.onReceiveValue(WebChromeClient.FileChooserParams.parseResult(res, data));
            escolhaArquivo = null;
        }
    }

    // ---------- Google Play Billing ----------
    private void conectarBilling(Runnable depois) {
        if (billing.isReady()) { if (depois != null) depois.run(); return; }
        billing.startConnection(new BillingClientStateListener() {
            @Override public void onBillingSetupFinished(BillingResult r) {
                if (r.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                    if (depois != null) depois.run();
                } else js("window.__playErro&&window.__playErro(" + JSONObject.quote("billing:" + r.getResponseCode() + " " + r.getDebugMessage()) + ")");
            }
            @Override public void onBillingServiceDisconnected() { }
        });
    }

    private void js(final String codigo) {
        runOnUiThread(() -> { if (web != null) web.evaluateJavascript(codigo, null); });
    }

    @Override
    public void onPurchasesUpdated(BillingResult r, List<Purchase> compras) {
        int c = r.getResponseCode();
        if (c == BillingClient.BillingResponseCode.OK && compras != null) {
            for (Purchase p : compras) avisarCompra(p, false);
        } else if (c == BillingClient.BillingResponseCode.USER_CANCELED) {
            js("window.__playCancelou&&window.__playCancelou()");
        } else {
            js("window.__playErro&&window.__playErro(" + JSONObject.quote("compra:" + c + " " + r.getDebugMessage()) + ")");
        }
    }

    private void avisarCompra(Purchase p, boolean quieto) {
        if (p.getPurchaseState() != Purchase.PurchaseState.PURCHASED) {
            if (!quieto) js("window.__playErro&&window.__playErro('Pagamento pendente. O item chega quando o pagamento for confirmado.')");
            return;
        }
        for (String sku : p.getProducts())
            js("window.__playComprou&&window.__playComprou(" + JSONObject.quote(sku) + "," + JSONObject.quote(p.getPurchaseToken()) + "," + quieto + ")");
    }

    /** Funções que o jogo (JavaScript) chama: window.AndroidPlay.xxx */
    private class Ponte {
        @JavascriptInterface public String versao() { return BuildConfig.VERSION_NAME; }

        /** ids = JSON ["vip30", ...] → responde em window.__playDetalhes([{id, preco, texto}]) */
        @JavascriptInterface public void detalhes(final String ids) {
            conectarBilling(() -> {
                try {
                    JSONArray a = new JSONArray(ids);
                    List<QueryProductDetailsParams.Product> lista = new ArrayList<>();
                    for (int i = 0; i < a.length(); i++)
                        lista.add(QueryProductDetailsParams.Product.newBuilder().setProductId(a.getString(i)).setProductType(BillingClient.ProductType.INAPP).build());
                    billing.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(lista).build(), (r, res) -> {
                        JSONArray out = new JSONArray();
                        try {
                                                        List<ProductDetails> ds = res == null ? null : res.getProductDetailsList();
                            if (ds != null) for (ProductDetails d : ds) {
                                produtos.put(d.getProductId(), d);
                                ProductDetails.OneTimePurchaseOfferDetails o = d.getOneTimePurchaseOfferDetails();
                                if (o == null) continue;
                                out.put(new JSONObject().put("id", d.getProductId()).put("preco", o.getPriceAmountMicros() / 1e6).put("texto", o.getFormattedPrice()));
                            }
                        } catch (Exception e) { }
                        js("window.__playDetalhes&&window.__playDetalhes(" + out + "," + JSONObject.quote("r" + r.getResponseCode() + " " + r.getDebugMessage()) + ")");
                    });
                } catch (Exception e) {
                    js("window.__playErro&&window.__playErro(" + JSONObject.quote("detalhes:" + e.getMessage()) + ")");
                }
            });
        }

        @JavascriptInterface public void comprar(final String sku, final String conta) {
            runOnUiThread(() -> conectarBilling(() -> {
                ProductDetails d = produtos.get(sku);
                if (d == null) { js("window.__playErro&&window.__playErro('Produto ainda não carregou. Tente de novo.')"); return; }
                List<BillingFlowParams.ProductDetailsParams> ps = new ArrayList<>();
                ps.add(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(d).build());
                BillingFlowParams.Builder b = BillingFlowParams.newBuilder().setProductDetailsParamsList(ps);
                if (conta != null && !conta.isEmpty()) b.setObfuscatedAccountId(conta);
                BillingResult r = billing.launchBillingFlow(MainActivity.this, b.build());
                if (r.getResponseCode() != BillingClient.BillingResponseCode.OK)
                    js("window.__playErro&&window.__playErro(" + JSONObject.quote("abrir:" + r.getResponseCode() + " " + r.getDebugMessage()) + ")");
            }));
        }

        /** consome (itens que podem ser comprados de novo: VIP e dinheiro) */
        @JavascriptInterface public void consumir(final String token) {
            conectarBilling(() -> billing.consumeAsync(ConsumeParams.newBuilder().setPurchaseToken(token).build(), (r, t) -> { }));
        }

        @JavascriptInterface public void reconhecer(final String token) {
            conectarBilling(() -> billing.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(token).build(), r -> { }));
        }

        /** compras pagas que ainda não foram entregues (o app fechou no meio) */
        @JavascriptInterface public void pendentes() {
            conectarBilling(() -> billing.queryPurchasesAsync(
                    QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build(),
                    (r, lista) -> { if (lista != null) for (Purchase p : lista) avisarCompra(p, true); }));
        }
    }
}
