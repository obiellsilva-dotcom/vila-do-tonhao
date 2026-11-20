package br.com.viladotonhao.app;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
@RunWith(RobolectricTestRunner.class)
@Config(sdk = 30)
public class AbreAndroid11 extends AbreTest { @Test public void abre() { abreEm(); } }
