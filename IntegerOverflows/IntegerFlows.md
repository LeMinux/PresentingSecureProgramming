<talk about bits in bytes>
<talk about how n + 1 is always enough to catch overflows>
<talk about unsigned overflows>
<talk about singed overflows>
    <only on same signs can it overflow on addition>
<signed to unsigned conversions>
<truncations>
<sign extenstions>

<Talk about why code below doesn't work>

if (x < TYPE_MAX_SIZE) {
    if (!(ptr = (unsigned char *)malloc(x))) abort( );
} else {
    /* Handle the error condition ... */
}

In this example the data type of x depends on what behavior will happen. If x is a signed value
it will result in a very large allocation since malloc accepts a size_t     
