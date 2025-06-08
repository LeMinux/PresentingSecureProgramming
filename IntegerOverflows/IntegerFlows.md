//talk about bits in bytes
//talk about how n + 1 is always enough to catch overflows
//talk about unsigned overflows
//talk about signed overflows
//signed to unsigned conversions
//truncations
//sign extenstions

//Talk about why code below doesn't work
```
/* x is a signed int in this case */
if (x < TYPE_MAX_SIZE) {
    ptr = malloc(x)
    if (ptr == NULL)
        abort();
} else {
    /* Handle the error condition ... */
}
```

In this example the data type of x depends on what behavior will happen. If x is a signed value
it will result in a very large allocation since malloc accepts a size_t
