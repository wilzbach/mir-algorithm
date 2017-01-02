module mir.ndslice.field;

import mir.internal.utility;
import std.traits;

///
struct MapField(Field, alias fun)
{
    ///
    Field _field;

    auto __map(alias fun1)()
    {
        import mir.funcitonal: pipe;
        return MapField!(Field, pipe!(fun, fun1))(_field);
    }

    auto ref opIndex()(ptrdiff_t index)
    {
        return fun(_field[index]);
    }
}

/++
+/
auto mapField(alias fun, Field)(Field field)
{
    static if (__traits(hasMember, Field, "__map"))
        return field.__map!fun;
    else
       return MapField!(Field, fun)(field);
}

///
struct RepeatField(T)
{
    static if (is(T == class) || is(T == interface) || is(T : Unqual!T) && is(Unqual!T : T))
        ///
        alias UT = Unqual!T;
    else
        ///
        alias UT = T;

    ///
    UT _value;

    auto ref T opIndex(ptrdiff_t)
    { return cast(T) _value; }
}

///
struct BitwiseField(Field, I = typeof(Field.init[size_t.init]))
    if (isIntegral!I)
{
    import core.bitop: bsr;
    private enum shift = bsr(I.sizeof) + 3;
    private enum mask = (1 << shift) - 1;

    ///
    Field _field;

    bool opIndex(size_t index)
    {
        return ((_field[index >> shift] & (I(1) << (index & mask)))) != 0;
    }

    static if (__traits(compiles, Field.init[size_t.init] |= I.init))
    bool opIndexAssign()(bool value, size_t index)
    {
        auto m = I(1) << (index & mask);
        index >>= shift;
        if (value)
            _field[index] |= m;
        else
            _field[index] &= ~m;
        return value;
    }
}

///
unittest
{
	import mir.ndslice.iterator: FieldIterator;
    short[10] data;
    auto f = FieldIterator!(BitwiseField!(short*))(0, BitwiseField!(short*)(data.ptr));
    f[123] = true;
    f++;
    assert(f[122]);
}

/++
Iterator composed of indexes.
See_also: $(LREF ndiota)
+/
struct ndIotaField(size_t N)
    if (N)
{
    ///
    size_t[N - 1] _lengths;

    size_t[N] opIndex(size_t index) const
    {
        size_t[N] indexes = void;
        foreach_reverse (i; Iota!(N - 1))
        {
            indexes[i + 1] = index % _lengths[i];
            index /= _lengths[i];
        }
        indexes[0] = index;
        return indexes;
    }
}
