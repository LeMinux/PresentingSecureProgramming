//talk about bits in bytes
//talk about how n + 1 is always enough to catch overflows
//talk about unsigned overflows
//talk about signed overflows
//signed to unsigned conversions
//truncations
//sign extenstions

```
void initialize_array(int size){

    if(size > MAX_ARRAY_SIZE){
        /* handle error */
    }

    array = malloc(size);

    /* rest of function */
}
```
If we look at this code example we can see validation of the function parameter is conducted.
This check does work if the parameter is larger than the max size.
However, because of type conversion there is a bug that will allocate a very large space if a negative number is passed.
A negative number would pass the check, but because malloc takes a size_t it would allocate a very large amount.
//explain signed and unsigned

