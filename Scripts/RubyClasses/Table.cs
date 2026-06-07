using System;
using MRuby.Library.Language;
using MRuby.Library.Mapper;
using RGSSGodot;

namespace RGSSUnity.RubyClasses
{
    public class TableData : RubyData
    {
        public int XSize;
        public int YSize;
        public int ZSize;
        public int[] Data = Array.Empty<int>();

        public TableData(RbState state) : base(state)
        {
        }
    }

    [RbClass("Table", "Object", "Unity")]
    public static class Table
    {
        [RbClassMethod("new_xyz")]
        private static RbValue New(RbState state, RbValue self, RbValue xsize, RbValue ysize, RbValue zsize)
        {
            var xSize = (int)xsize.ToIntUnchecked();
            var ySize = (int)ysize.ToIntUnchecked();
            var zSize = (int)zsize.ToIntUnchecked();

            if (xSize < 0 || ySize < 0 || zSize < 0)
            {
                state.RaiseRGSSError("Invalid size");
                return state.RbNil;
            }

            var tableData = CreateTableData(state, xSize, ySize, zSize);

            var cls = self.ToClass();
            var res = cls.NewObjectWithRData(tableData);
            return res;
        }

        [RbInstanceMethod("xsize")]
        private static RbValue GetXSize(RbState state, RbValue self)
            => ((long)self.GetRDataObject<TableData>().XSize).ToValue(state);

        [RbInstanceMethod("ysize")]
        private static RbValue GetYSize(RbState state, RbValue self)
            => ((long)self.GetRDataObject<TableData>().YSize).ToValue(state);

        [RbInstanceMethod("zsize")]
        private static RbValue GetZSize(RbState state, RbValue self)
            => ((long)self.GetRDataObject<TableData>().ZSize).ToValue(state);

        [RbInstanceMethod("resize")]
        private static RbValue Resize(RbState state, RbValue self, RbValue xsize, RbValue ysize, RbValue zsize)
        {
            var xSize = (int)xsize.ToIntUnchecked();
            var ySize = (int)ysize.ToIntUnchecked();
            var zSize = (int)zsize.ToIntUnchecked();

            if (xSize < 0 || ySize < 0 || zSize < 0)
            {
                state.RaiseRGSSError("Invalid size");
                return state.RbNil;
            }

            var tableData = self.GetRDataObject<TableData>();
            var newSize = xSize;
            if (ySize != 0)
            {
                newSize *= ySize;
                if (zSize != 0)
                {
                    newSize *= zSize;
                }
            }

            tableData.XSize = xSize;
            tableData.YSize = ySize;
            tableData.ZSize = zSize;

            Array.Resize(ref tableData.Data, (int)newSize);
            return state.RbNil;
        }

        [RbInstanceMethod("get_x")]
        private static RbValue GetX(RbState state, RbValue self, RbValue x)
        {
            var tableData = self.GetRDataObject<TableData>();
            var unboxedX = (int)x.ToIntUnchecked();
            if (unboxedX < 0 || unboxedX >= tableData.Data.Length)
            {
                return state.RbNil;
            }
            var data = tableData.Data[unboxedX];
            return data.ToValue(state);
        }

        [RbInstanceMethod("get_xy")]
        private static RbValue GetXY(RbState state, RbValue self, RbValue x, RbValue y)
        {
            var tableData = self.GetRDataObject<TableData>();
            var unboxedX = (int)x.ToIntUnchecked();
            var unboxedY = (int)y.ToIntUnchecked();
            var index = unboxedX + unboxedY * tableData.XSize;
            if (index < 0 || index >= tableData.Data.Length)
            {
                return state.RbNil;
            }

            var data = tableData.Data[index];
            return data.ToValue(state);
        }

        [RbInstanceMethod("get_xyz")]
        private static RbValue GetXYZ(RbState state, RbValue self, RbValue x, RbValue y, RbValue z)
        {
            var tableData = self.GetRDataObject<TableData>();
            var unboxedX = (int)x.ToIntUnchecked();
            var unboxedY = (int)y.ToIntUnchecked();
            var unboxedZ = (int)z.ToIntUnchecked();

            var index = unboxedX + unboxedY * tableData.XSize + unboxedZ * tableData.XSize * tableData.YSize;

            if (index < 0 || index >= tableData.Data.Length)
            {
                return state.RbNil;
            }

            var data = tableData.Data[index];
            return data.ToValue(state);
        }

        [RbInstanceMethod("set_x")]
        private static RbValue SetX(RbState state, RbValue self, RbValue x, RbValue value)
        {
            var tableData = self.GetRDataObject<TableData>();
            var unboxedX = (int)x.ToIntUnchecked();
            if (unboxedX < 0 || unboxedX >= tableData.Data.Length)
            {
                return state.RbNil;
            }
            tableData.Data[unboxedX] = (short)(long)value.ToIntUnchecked();
            return state.RbNil;
        }

        [RbInstanceMethod("set_xy")]
        private static RbValue SetXY(RbState state, RbValue self, RbValue x, RbValue y, RbValue value)
        {
            var tableData = self.GetRDataObject<TableData>();
            var unboxedX = (int)x.ToIntUnchecked();
            var unboxedY = (int)y.ToIntUnchecked();
            var index = unboxedX + unboxedY * tableData.XSize;
            if (index < 0 || index >= tableData.Data.Length)
            {
                return state.RbNil;
            }
            tableData.Data[index] = (short)(long)value.ToIntUnchecked();
            return state.RbNil;
        }

        [RbInstanceMethod("set_xyz")]
        private static RbValue SetXYZ(RbState state, RbValue self, RbValue x, RbValue y, RbValue z, RbValue value)
        {
            var tableData = self.GetRDataObject<TableData>();
            var unboxedX = (int)x.ToIntUnchecked();
            var unboxedY = (int)y.ToIntUnchecked();
            var unboxedZ = (int)z.ToIntUnchecked();
            var index = unboxedX + unboxedY * tableData.XSize + unboxedZ * tableData.XSize * tableData.YSize;
            if (index < 0 || index >= tableData.Data.Length)
            {
                return state.RbNil;
            }
            tableData.Data[index] = (short)(long)value.ToIntUnchecked();
            return state.RbNil;
        }

        private static TableData CreateTableData(RbState state, int xSize, int ySize, int zSize)
        {
            var size = xSize;
            if (ySize != 0)
            {
                size *= ySize;
                if (zSize != 0)
                {
                    size *= zSize;
                }
            }

            var tableData = new TableData(state)
            {
                XSize = xSize,
                YSize = ySize,
                ZSize = zSize,
                Data = new int[size],
            };
            return tableData;
        }
    }
}
