using System;
using MRuby.Library.Language;
using MRuby.Library.Mapper;

namespace RGSSUnity.RubyClasses;

[RbClass("Tilemap", "Object", "Unity")]
public static class Tilemap
{
    [RbClassMethod("new")]
    public static RbValue New(RbState state, RbValue self, RbValue viewport)
    {
        var viewportData = viewport.IsNil ? null : viewport.GetRDataObject<ViewportData>();
        var data = new TilemapData(state)
        {
            Viewport = viewportData,
        };

        if (viewportData is not null)
            GameRenderManager.Instance.RegisterTilemap(data, viewportData);

        var obj = self.ToClass().NewObjectWithRData(data);
        obj["@viewport"] = viewport;
        obj["@map_data"] = state.RbNil;
        obj["@flash_data"] = state.RbNil;
        obj["@flags"] = state.RbNil;
        return obj;
    }

    [RbInstanceMethod("dispose")]
    public static RbValue Dispose(RbState state, RbValue self)
    {
        var data = self.GetRDataObject<TilemapData>();
        if (data.Disposed)
            return state.RbNil;

        GameRenderManager.Instance.UnregisterTilemap(data);
        data.Disposed = true;
        data.MapData = null;
        data.FlashData = null;
        data.Flags = null;
        data.Viewport = null;
        data.Node = null;
        for (var i = 0; i < data.Bitmaps.Length; i++)
            data.Bitmaps[i] = null;
        return state.RbNil;
    }

    [RbInstanceMethod("disposed?")]
    public static RbValue Disposed(RbState state, RbValue self)
        => self.GetRDataObject<TilemapData>().Disposed.ToValue(state);

    [RbInstanceMethod("update")]
    public static RbValue Update(RbState state, RbValue self)
    {
        // Advances autotile animation and the flash-tile blink, mirroring RGSS3
        // Tilemap#update (once per frame). They use separate cadences.
        var data = self.GetRDataObject<TilemapData>();
        data.AnimationTick++;
        data.FlashTick++;
        return state.RbNil;
    }

    // ── bitmaps[] proxy support (called by TilemapBitmapsProxy in tilemap.rb) ──────
    [RbInstanceMethod("set_bitmap")]
    public static RbValue SetBitmap(RbState state, RbValue self, RbValue index, RbValue bitmap)
    {
        var data = self.GetRDataObject<TilemapData>();
        var i = (int)index.ToIntUnchecked();
        if (i < 0 || i >= data.Bitmaps.Length)
            return state.RbNil;

        data.Bitmaps[i] = bitmap.IsNil ? null : bitmap.GetRDataObject<BitmapData>();
        data.LayersDirty = true;
        return state.RbNil;
    }

    [RbInstanceMethod("get_bitmap")]
    public static RbValue GetBitmap(RbState state, RbValue self, RbValue index)
    {
        // The Ruby proxy stores the wrapper objects; this native getter is only a
        // fallback and returns nil (the wrapper side keeps the real Bitmap objects).
        return state.RbNil;
    }

    [RbInstanceMethod("map_data=")]
    public static RbValue SetMapData(RbState state, RbValue self, RbValue mapData)
    {
        var data = self.GetRDataObject<TilemapData>();
        var newTable = mapData.IsNil ? null : mapData.GetRDataObject<TableData>();
        // RMVA reassigns the same Table every frame; only flag dirty when it truly changes.
        if (!ReferenceEquals(newTable, data.MapData))
        {
            data.MapData = newTable;
            data.LayersDirty = true;
        }
        self["@map_data"] = mapData;
        return state.RbNil;
    }

    [RbInstanceMethod("map_data")]
    public static RbValue GetMapData(RbState state, RbValue self) => self["@map_data"];

    [RbInstanceMethod("flash_data=")]
    public static RbValue SetFlashData(RbState state, RbValue self, RbValue flashData)
    {
        self.GetRDataObject<TilemapData>().FlashData = flashData.IsNil ? null : flashData.GetRDataObject<TableData>();
        self["@flash_data"] = flashData;
        return state.RbNil;
    }

    [RbInstanceMethod("flash_data")]
    public static RbValue GetFlashData(RbState state, RbValue self) => self["@flash_data"];

    [RbInstanceMethod("flags=")]
    public static RbValue SetFlags(RbState state, RbValue self, RbValue flags)
    {
        var data = self.GetRDataObject<TilemapData>();
        data.Flags = flags.IsNil ? null : flags.GetRDataObject<TableData>();
        data.LayersDirty = true;
        self["@flags"] = flags;
        return state.RbNil;
    }

    [RbInstanceMethod("flags")]
    public static RbValue GetFlags(RbState state, RbValue self) => self["@flags"];

    [RbInstanceMethod("viewport")]
    public static RbValue GetViewport(RbState state, RbValue self) => self["@viewport"];

    [RbInstanceMethod("viewport=")]
    public static RbValue SetViewport(RbState state, RbValue self, RbValue viewport)
    {
        var data = self.GetRDataObject<TilemapData>();
        var viewportData = viewport.IsNil ? null : viewport.GetRDataObject<ViewportData>();
        if (viewportData is not null)
            GameRenderManager.Instance.RegisterTilemap(data, viewportData);
        self["@viewport"] = viewport;
        return state.RbNil;
    }

    [RbInstanceMethod("ox")]
    public static RbValue GetOx(RbState state, RbValue self)
        => ((long)self.GetRDataObject<TilemapData>().Ox).ToValue(state);

    [RbInstanceMethod("ox=")]
    public static RbValue SetOx(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<TilemapData>().Ox = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("oy")]
    public static RbValue GetOy(RbState state, RbValue self)
        => ((long)self.GetRDataObject<TilemapData>().Oy).ToValue(state);

    [RbInstanceMethod("oy=")]
    public static RbValue SetOy(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<TilemapData>().Oy = ToFloat(value);
        return state.RbNil;
    }

    [RbInstanceMethod("visible")]
    public static RbValue GetVisible(RbState state, RbValue self)
        => self.GetRDataObject<TilemapData>().Visible.ToValue(state);

    [RbInstanceMethod("visible=")]
    public static RbValue SetVisible(RbState state, RbValue self, RbValue value)
    {
        self.GetRDataObject<TilemapData>().Visible = value.IsTrue;
        return state.RbNil;
    }

    private static float ToFloat(RbValue value)
        => value.IsFloat ? Convert.ToSingle(value.ToFloatUnchecked()) : Convert.ToSingle(value.ToIntUnchecked());
}
