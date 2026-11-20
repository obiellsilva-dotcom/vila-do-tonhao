package br.com.viladotonhao.app;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
@RunWith(RobolectricTestRunner.class)
@Config(sdk = 26)
public class AbreAndroid8_0 extends AbreTest { @Test public void abre() { abreEm(); } }
