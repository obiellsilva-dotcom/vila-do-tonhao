package br.com.viladotonhao.app;
import static org.junit.Assert.*;
import android.webkit.WebView;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import org.robolectric.shadows.ShadowWebView;

@RunWith(RobolectricTestRunner.class)
public class AbreTest {
    private void abreEm() {
        MainActivity a = Robolectric.buildActivity(MainActivity.class).setup().get();
        assertFalse("o app fechou", a.isFinishing());
        ShadowWebView sw = null;
        android.view.ViewGroup c = a.findViewById(android.R.id.content);
        assertTrue(c.getChildAt(0) instanceof WebView);
        sw = Shadows.shadowOf((WebView) c.getChildAt(0));
        assertEquals("https://viladotonhao.com.br/?app=1", sw.getLastLoadedUrl());
        assertNotNull("ponte da loja", sw.getJavascriptInterface("AndroidPlay"));
        // simula girar a tela / voltar do fundo
        a.onWindowFocusChanged(true);
        // botões da loja chamados pelo jogo não podem derrubar o app
        Object ponte = sw.getJavascriptInterface("AndroidPlay");
        try {
            for (java.lang.reflect.Method m : ponte.getClass().getDeclaredMethods()) {
                m.setAccessible(true);
                if (m.getName().equals("detalhes")) m.invoke(ponte, "[\"vip30\",\"din10\"]");
                if (m.getName().equals("comprar")) m.invoke(ponte, "vip30", "conta-teste");
                if (m.getName().equals("pendentes")) m.invoke(ponte);
                if (m.getName().equals("consumir")) m.invoke(ponte, "token-teste");
                if (m.getName().equals("versao")) assertNotNull(m.invoke(ponte));
            }
        } catch (Exception e) { throw new AssertionError("a loja derrubou o app", e); }
        org.robolectric.shadows.ShadowLooper.idleMainLooper();
        assertFalse("o app fechou depois da loja", a.isFinishing());
        // vai para o fundo e volta
        Robolectric.buildActivity(MainActivity.class).setup().pause().resume().destroy();
    }
    @Test @Config(sdk = 24) public void android7_0() { abreEm(); }
    @Test @Config(sdk = 25) public void android7_1() { abreEm(); }
    @Test @Config(sdk = 26) public void android8_0() { abreEm(); }
    @Test @Config(sdk = 27) public void android8_1() { abreEm(); }
    @Test @Config(sdk = 28) public void android9() { abreEm(); }
    @Test @Config(sdk = 29) public void android10() { abreEm(); }
    @Test @Config(sdk = 30) public void android11() { abreEm(); }
    @Test @Config(sdk = 31) public void android12() { abreEm(); }
    @Test @Config(sdk = 32) public void android12L() { abreEm(); }
    @Test @Config(sdk = 33) public void android13() { abreEm(); }
    @Test @Config(sdk = 34) public void android14() { abreEm(); }
    @Test @Config(sdk = 35) public void android15() { abreEm(); }
}
