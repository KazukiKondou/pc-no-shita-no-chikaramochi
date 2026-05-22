using System;
using System.Drawing;
using System.Drawing.Drawing2D;

namespace PCNoShitaNoChikaramochi;

/// <summary>
/// Mac 版 CharacterIcon.swift と同じ描画ロジックを GDI+ に移植したもの。
/// 100x100 の仮想座標で描いて、与えられたサイズにスケールする。
/// </summary>
public static class CharacterRenderer
{
    public static Bitmap Render(CharacterState state, double phase, AppearanceSnapshot appearance, int pixelSize)
    {
        var bmp = new Bitmap(pixelSize, pixelSize, System.Drawing.Imaging.PixelFormat.Format32bppPArgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.HighQuality;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.Clear(Color.Transparent);

            var painter = new Painter(g, pixelSize, state, phase, appearance);
            painter.Paint();
        }
        return bmp;
    }

    private class Painter
    {
        private readonly Graphics _g;
        private readonly float _scale;
        private readonly float _cx;
        private readonly float _cy;
        private readonly CharacterState _state;
        private readonly double _phase;
        private readonly AppearanceSnapshot _app;

        private Color ShirtColor => AppearanceColors.Shirt(_app.ShirtColor);
        private Color SkinColor => AppearanceColors.Skin(_app.SkinTone);
        private Color SkinShade => AppearanceColors.SkinShade(_app.SkinTone);
        private Color HairColor => AppearanceColors.Hair;
        private Color ShortsColor => AppearanceColors.Shorts;
        private Color BarColor => AppearanceColors.Bar;
        private Color PlateColor => AppearanceColors.Plate(_state);

        public Painter(Graphics g, int pixelSize, CharacterState state, double phase, AppearanceSnapshot app)
        {
            _g = g;
            _scale = pixelSize / 100f;
            _cx = pixelSize / 2f;
            _cy = pixelSize / 2f;
            _state = state;
            _phase = phase;
            _app = app;
        }

        private PointF P(double x, double y) => new((float)(_cx + x * _scale), (float)(_cy + y * _scale));

        private RectangleF R(double x, double y, double w, double h)
        {
            var tl = P(x, y);
            var br = P(x + w, y + h);
            return RectangleF.FromLTRB(tl.X, tl.Y, br.X, br.Y);
        }

        private float S(double v) => (float)(v * _scale);

        public void Paint()
        {
            switch (_state)
            {
                case CharacterState.Crushed:
                    PaintCrushed();
                    break;
                case CharacterState.Struggling:
                    PaintLifter(armPhase: 0.45, leanY: 6, strain: true);
                    break;
                case CharacterState.Heavy:
                    PaintLifter(armPhase: _phase * 0.9 + 0.05, leanY: 3, strain: true);
                    break;
                default:
                    PaintLifter(armPhase: _phase, leanY: 0, strain: false);
                    break;
            }
        }

        // MARK: - Standing lifter

        private void PaintLifter(double armPhase, double leanY, bool strain)
        {
            var t = armPhase;

            // ---- 脚 ----
            const double legW = 8.0;
            var legTop = 18.0 + leanY;
            var legBot = 42.0 + leanY;
            FillRoundedRect(R(-8, legTop, legW, legBot - legTop), 3, ShortsColor);
            FillRoundedRect(R(8 - legW, legTop, legW, legBot - legTop), 3, ShortsColor);

            // ---- 胴体 (男性=矩形、女性=A-lineドレス) ----
            var torsoTop = -8.0 + leanY;
            var torsoBot = 20.0 + leanY;

            using var torsoPath = new GraphicsPath();
            if (_app.Gender == Gender.Female)
            {
                // 台形 (裾が広がる)
                var dressBot = torsoBot + 4;
                BuildPath(torsoPath,
                    P(-12, torsoTop + 1),
                    pb => pb.QuadTo(P(-11.5, torsoTop), P(-12, torsoTop))
                          .LineTo(P(11.5, torsoTop))
                          .QuadTo(P(12, torsoTop + 1), P(12, torsoTop))
                          .LineTo(P(19, dressBot - 1))
                          .QuadTo(P(18, dressBot), P(19, dressBot))
                          .LineTo(P(-18, dressBot))
                          .QuadTo(P(-19, dressBot - 1), P(-19, dressBot))
                          .Close());
            }
            else
            {
                AddRoundedRect(torsoPath, R(-14, torsoTop, 28, torsoBot - torsoTop), 4);
            }

            using (var brush = new SolidBrush(ShirtColor))
            {
                _g.FillPath(brush, torsoPath);
            }
            if (_app.ShirtColor == ShirtColor.White)
            {
                using var pen = new Pen(Color.FromArgb(128, Color.Gray), S(0.7));
                _g.DrawPath(pen, torsoPath);
            }

            // ---- 首 ----
            FillRect(R(-3, -12 + leanY, 6, 5), SkinShade);

            // ---- 頭 ----
            var headCY = -22.0 + leanY;

            // 女性: ロングヘア背面 (頭/顔の後ろ)
            if (_app.Gender == Gender.Female)
            {
                using var hairBack = new GraphicsPath();
                BuildPath(hairBack,
                    P(-10, headCY),
                    pb => pb.QuadTo(P(10, headCY), P(0, headCY - 14))
                          .QuadTo(P(9, 4 + leanY), P(15, headCY + 18))
                          .LineTo(P(-9, 4 + leanY))
                          .QuadTo(P(-10, headCY), P(-15, headCY + 18))
                          .Close());
                FillPath(hairBack, HairColor);
            }

            FillEllipse(R(-10, headCY - 10, 20, 20), SkinColor);

            // 前髪
            if (_app.Gender == Gender.Female)
            {
                using var bangs = new GraphicsPath();
                BuildPath(bangs,
                    P(-10, headCY - 5),
                    pb => pb.QuadTo(P(10, headCY - 5), P(0, headCY - 13))
                          .LineTo(P(7, headCY))
                          .QuadTo(P(1, headCY - 4), P(4, headCY - 4))
                          .QuadTo(P(-1, headCY - 4), P(0, headCY - 1))
                          .QuadTo(P(-7, headCY), P(-4, headCY - 4))
                          .Close());
                FillPath(bangs, HairColor);
            }
            else
            {
                using var hair = new GraphicsPath();
                BuildPath(hair,
                    P(-10, headCY - 5),
                    pb => pb.QuadTo(P(10, headCY - 5), P(0, headCY - 13))
                          .LineTo(P(8, headCY - 2))
                          .QuadTo(P(-8, headCY - 2), P(0, headCY - 6))
                          .Close());
                FillPath(hair, HairColor);
            }

            // ---- 顔 ----
            DrawFace(headCY, strain);

            // ---- 腕 + ウェイト ----
            var leftShoulder = P(-12, -6 + leanY);
            var rightShoulder = P(12, -6 + leanY);

            var handDownY = 14.0 + leanY;
            var handUpY = headCY - 22.0;
            var handY = handDownY + (handUpY - handDownY) * t;

            var handXSpread = 16.0 + (1.0 - t) * 6.0;
            var leftHand = P(-handXSpread, handY);
            var rightHand = P(handXSpread, handY);

            var armWidth = S(5.5);
            DrawLine(leftShoulder, leftHand, SkinColor, armWidth, true);
            DrawLine(rightShoulder, rightHand, SkinColor, armWidth, true);

            // ---- ウェイト ----
            if (_state.Lift() == LiftKind.Dumbbell)
            {
                DrawDumbbell(leftHand);
                DrawDumbbell(rightHand);
            }
            else
            {
                DrawBarbell(leftHand, rightHand, strain);
            }

            if (_state == CharacterState.Struggling)
            {
                DrawSweat(headCY);
            }
        }

        // MARK: - Crushed

        private void PaintCrushed()
        {
            // 地面ライン
            DrawLine(P(-45, 38), P(45, 38), Color.FromArgb(102, Color.Gray), S(1.5), false);

            // 横たわった脚
            FillRoundedRect(R(-22, 28, 30, 8), 4, ShortsColor);

            // 胴体
            FillRoundedRect(R(-6, 16, 28, 12), 4, ShirtColor);

            // 女性: 床に広がる長い髪 (頭の左側)
            if (_app.Gender == Gender.Female)
            {
                using var hairBack = new GraphicsPath();
                BuildPath(hairBack,
                    P(20, 14),
                    pb => pb.QuadTo(P(0, 18), P(8, 11))
                          .QuadTo(P(2, 27), P(-4, 22))
                          .LineTo(P(22, 27))
                          .Close());
                FillPath(hairBack, HairColor);
            }

            // 頭 (右側)
            FillEllipse(R(17, 13, 18, 18), SkinColor);

            // 髪 (頭頂)
            using (var hair = new GraphicsPath())
            {
                BuildPath(hair,
                    P(30, 14),
                    pb => pb.QuadTo(P(34, 23), P(38, 17))
                          .LineTo(P(30, 22))
                          .Close());
                FillPath(hair, HairColor);
            }

            // X目
            const double eyeSize = 2.4;
            (double, double)[] eyes = { (25.0, 19.0), (29.0, 21.0) };
            foreach (var (ex, ey) in eyes)
            {
                DrawLine(P(ex - eyeSize, ey - eyeSize), P(ex + eyeSize, ey + eyeSize), Color.Black, S(1.4), true);
                DrawLine(P(ex + eyeSize, ey - eyeSize), P(ex - eyeSize, ey + eyeSize), Color.Black, S(1.4), true);
            }

            // 舌
            FillRoundedRect(R(23, 25, 4, 3), 1.5, Color.FromArgb(242, 115, 140));

            // バーベル
            DrawLine(P(-45, 8), P(45, 8), BarColor, S(4.5), true);

            DrawPlate(-42, 8, 12, 32);
            DrawPlate(30, 8, 12, 32);
            DrawPlate(-28, 8, 6, 22);
            DrawPlate(22, 8, 6, 22);

            // 衝撃線
            (double, double)[] sparks = { (-30.0, -5.0), (32.0, -8.0), (0.0, -14.0) };
            foreach (var (dx, dy) in sparks)
            {
                DrawLine(P(dx - 3, dy - 3), P(dx + 3, dy + 3), Color.FromArgb(230, Color.Gold), S(1.5), false);
                DrawLine(P(dx + 3, dy - 3), P(dx - 3, dy + 3), Color.FromArgb(230, Color.Gold), S(1.5), false);
            }
        }

        // MARK: - Sub-elements

        private void DrawFace(double headCY, bool strain)
        {
            const double eyeOffsetX = 3.5;
            const double eyeR = 1.6;
            var eyeY = headCY - 1.0;
            var mouthY = headCY + 4.0;

            // 目
            if (_state == CharacterState.VeryEasy)
            {
                // ^_^ (にこにこ閉じ目)
                for (int sign = -1; sign <= 1; sign += 2)
                {
                    using var path = new GraphicsPath();
                    BuildPath(path,
                        P(sign * eyeOffsetX - 2, eyeY + 1),
                        pb => pb.QuadTo(P(sign * eyeOffsetX + 2, eyeY + 1), P(sign * eyeOffsetX, eyeY - 2)));
                    DrawPath(path, Color.Black, S(1.3), true);
                }
            }
            else if (strain)
            {
                // >_< (しかめ目)
                for (int sign = -1; sign <= 1; sign += 2)
                {
                    using var path = new GraphicsPath();
                    BuildPath(path,
                        P(sign * eyeOffsetX - 2, eyeY - 1),
                        pb => pb.QuadTo(P(sign * eyeOffsetX + 2, eyeY - 1), P(sign * eyeOffsetX, eyeY + 2)));
                    DrawPath(path, Color.Black, S(1.4), true);
                }
            }
            else
            {
                // 普通の点目
                for (int sign = -1; sign <= 1; sign += 2)
                {
                    FillEllipse(R(sign * eyeOffsetX - eyeR, eyeY - eyeR, eyeR * 2, eyeR * 2), Color.Black);
                }
            }

            // 口
            switch (_state)
            {
                case CharacterState.VeryEasy:
                case CharacterState.Easy:
                    {
                        using var path = new GraphicsPath();
                        BuildPath(path,
                            P(-3, mouthY),
                            pb => pb.QuadTo(P(3, mouthY), P(0, mouthY + 2.5)));
                        DrawPath(path, Color.Black, S(1.2), true);
                    }
                    break;
                case CharacterState.Normal:
                    {
                        using var path = new GraphicsPath();
                        BuildPath(path,
                            P(-2, mouthY),
                            pb => pb.LineTo(P(2, mouthY)));
                        DrawPath(path, Color.Black, S(1.2), true);
                    }
                    break;
                case CharacterState.Heavy:
                    {
                        // 食いしばり (歯)
                        var rect = R(-3, mouthY - 1, 6, 2.5);
                        using var path = new GraphicsPath();
                        AddRoundedRect(path, rect, 0.5);
                        FillPath(path, Color.White);
                        DrawPath(path, Color.Black, S(0.8), false);
                        DrawLine(P(0, mouthY - 1), P(0, mouthY + 1.5), Color.Black, S(0.6), false);
                    }
                    break;
                case CharacterState.Struggling:
                    {
                        var rect = R(-3, mouthY - 1, 6, 4);
                        using var path = new GraphicsPath();
                        AddRoundedRect(path, rect, 1.5);
                        FillPath(path, Color.FromArgb(115, 26, 26));
                    }
                    break;
            }

            // veryEasy: 頬にキラキラ
            if (_state == CharacterState.VeryEasy)
            {
                for (int sign = -1; sign <= 1; sign += 2)
                {
                    var cx = sign * 7.5;
                    var cy = headCY + 3.0;
                    using var path = new GraphicsPath();
                    BuildPath(path,
                        P(cx, cy - 1.5),
                        pb => pb.LineTo(P(cx + 0.6, cy - 0.4))
                              .LineTo(P(cx + 1.5, cy))
                              .LineTo(P(cx + 0.6, cy + 0.4))
                              .LineTo(P(cx, cy + 1.5))
                              .LineTo(P(cx - 0.6, cy + 0.4))
                              .LineTo(P(cx - 1.5, cy))
                              .LineTo(P(cx - 0.6, cy - 0.4))
                              .Close());
                    FillPath(path, Color.Gold);
                }
            }
        }

        private void DrawDumbbell(PointF hand)
        {
            var handleW = S(12.0);
            var handleH = S(2.5);
            FillRoundedRect(new RectangleF(hand.X - handleW / 2, hand.Y - handleH / 2, handleW, handleH), 1, BarColor, isPixel: true);

            foreach (var off in new[] { -7.0f, 7.0f })
            {
                var wW = S(4.0);
                var wH = S(8.0);
                var rect = new RectangleF(hand.X + S(off) - wW / 2, hand.Y - wH / 2, wW, wH);
                FillRoundedRect(rect, 1.2, PlateColor, isPixel: true);
            }
        }

        private void DrawBarbell(PointF leftHand, PointF rightHand, bool strain)
        {
            var extend = S(12.0);
            var dx = rightHand.X - leftHand.X;
            var dy = rightHand.Y - leftHand.Y;
            var len = (float)Math.Max(0.001, Math.Sqrt(dx * dx + dy * dy));
            var ux = dx / len;
            var uy = dy / len;
            var barLeft = new PointF(leftHand.X - ux * extend, leftHand.Y - uy * extend);
            var barRight = new PointF(rightHand.X + ux * extend, rightHand.Y + uy * extend);

            DrawLine(barLeft, barRight, BarColor, S(3.5), true);

            double plateW = 5.5;
            double plateH = strain ? 22.0 : 18.0;

            DrawBarPlate(barLeft, plateW, plateH);
            DrawBarPlate(barRight, plateW, plateH);

            var innerL = new PointF(barLeft.X + ux * S(4), barLeft.Y + uy * S(4));
            var innerR = new PointF(barRight.X - ux * S(4), barRight.Y - uy * S(4));
            DrawBarPlate(innerL, 3.0, plateH * 0.6);
            DrawBarPlate(innerR, 3.0, plateH * 0.6);
        }

        private void DrawBarPlate(PointF center, double w, double h)
        {
            var pw = S(w);
            var ph = S(h);
            var rect = new RectangleF(center.X - pw / 2, center.Y - ph / 2, pw, ph);
            using (var brush = new SolidBrush(PlateColor)) _g.FillEllipse(brush, rect);
            using (var pen = new Pen(Color.FromArgb(102, Color.Black), S(0.6))) _g.DrawEllipse(pen, rect);
        }

        private void DrawPlate(double x, double y, double w, double h)
        {
            var rect = R(x - w / 2, y - h / 2, w, h);
            using (var brush = new SolidBrush(PlateColor)) _g.FillEllipse(brush, rect);
            using (var pen = new Pen(Color.FromArgb(102, Color.Black), 0.6f)) _g.DrawEllipse(pen, rect);
        }

        private void DrawSweat(double headCY)
        {
            const double sx = 10.5;
            var sy = headCY;
            using var path = new GraphicsPath();
            BuildPath(path,
                P(sx, sy - 2),
                pb => pb.QuadTo(P(sx + 2, sy + 2), P(sx + 2.5, sy))
                      .QuadTo(P(sx, sy - 2), P(sx - 2.5, sy))
                      .Close());
            FillPath(path, Color.FromArgb(102, 191, 242));
        }

        // MARK: - Helpers

        private void FillEllipse(RectangleF r, Color c)
        {
            using var brush = new SolidBrush(c);
            _g.FillEllipse(brush, r);
        }

        private void FillRect(RectangleF r, Color c)
        {
            using var brush = new SolidBrush(c);
            _g.FillRectangle(brush, r);
        }

        private void FillPath(GraphicsPath p, Color c)
        {
            using var brush = new SolidBrush(c);
            _g.FillPath(brush, p);
        }

        private void DrawPath(GraphicsPath p, Color c, float width, bool roundCap)
        {
            using var pen = new Pen(c, width);
            if (roundCap)
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                pen.LineJoin = LineJoin.Round;
            }
            _g.DrawPath(pen, p);
        }

        private void DrawLine(PointF a, PointF b, Color c, float width, bool roundCap)
        {
            using var pen = new Pen(c, width);
            if (roundCap)
            {
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
            }
            _g.DrawLine(pen, a, b);
        }

        private void FillRoundedRect(RectangleF rect, double radiusVirtual, Color c, bool isPixel = false)
        {
            var r = isPixel ? (float)radiusVirtual : S(radiusVirtual);
            using var path = new GraphicsPath();
            AddRoundedRectPixel(path, rect, r);
            using var brush = new SolidBrush(c);
            _g.FillPath(brush, path);
        }

        private void AddRoundedRect(GraphicsPath path, RectangleF rect, double radiusVirtual)
        {
            AddRoundedRectPixel(path, rect, S(radiusVirtual));
        }

        private void AddRoundedRectPixel(GraphicsPath path, RectangleF rect, float radius)
        {
            radius = Math.Min(radius, Math.Min(rect.Width, rect.Height) / 2);
            if (radius <= 0)
            {
                path.AddRectangle(rect);
                return;
            }
            var d = radius * 2;
            path.StartFigure();
            path.AddArc(rect.X, rect.Y, d, d, 180, 90);
            path.AddArc(rect.Right - d, rect.Y, d, d, 270, 90);
            path.AddArc(rect.Right - d, rect.Bottom - d, d, d, 0, 90);
            path.AddArc(rect.X, rect.Bottom - d, d, d, 90, 90);
            path.CloseFigure();
        }

        // PathBuilder (Swift Path に近い書き味)
        private void BuildPath(GraphicsPath path, PointF start, Action<PathBuilder> build)
        {
            var pb = new PathBuilder(path, start);
            path.StartFigure();
            build(pb);
        }

        private class PathBuilder
        {
            private readonly GraphicsPath _path;
            private PointF _current;

            public PathBuilder(GraphicsPath path, PointF start)
            {
                _path = path;
                _current = start;
            }

            public PathBuilder LineTo(PointF p)
            {
                _path.AddLine(_current, p);
                _current = p;
                return this;
            }

            public PathBuilder QuadTo(PointF to, PointF control)
            {
                var c1 = new PointF(_current.X + (control.X - _current.X) * 2f / 3f,
                                    _current.Y + (control.Y - _current.Y) * 2f / 3f);
                var c2 = new PointF(to.X + (control.X - to.X) * 2f / 3f,
                                    to.Y + (control.Y - to.Y) * 2f / 3f);
                _path.AddBezier(_current, c1, c2, to);
                _current = to;
                return this;
            }

            public PathBuilder Close()
            {
                _path.CloseFigure();
                return this;
            }
        }
    }
}
