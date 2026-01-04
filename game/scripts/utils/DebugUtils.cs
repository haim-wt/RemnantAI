using Godot;

namespace Remnant.Utils;

/// <summary>
/// Debug drawing and logging utilities.
/// Only active in debug builds.
/// </summary>
public static class DebugUtils
{
    #region Debug State

    private static bool _debugEnabled = OS.IsDebugBuild();
    private static Node3D? _drawNode;
    private static ImmediateMesh? _immediateMesh;
    private static MeshInstance3D? _meshInstance;
    private static StandardMaterial3D? _material;

    #endregion

    #region Initialization

    public static void Initialize(Node3D parent)
    {
        if (!_debugEnabled) return;

        _drawNode = parent;

        _immediateMesh = new ImmediateMesh();

        _meshInstance = new MeshInstance3D
        {
            Mesh = _immediateMesh,
            CastShadow = GeometryInstance3D.ShadowCastingSetting.Off
        };

        _material = new StandardMaterial3D
        {
            ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded,
            VertexColorUseAsAlbedo = true,
            Transparency = BaseMaterial3D.TransparencyEnum.Alpha
        };

        _meshInstance.MaterialOverride = _material;
        parent.AddChild(_meshInstance);
    }

    public static void Clear()
    {
        if (!_debugEnabled || _immediateMesh == null) return;
        _immediateMesh.ClearSurfaces();
    }

    #endregion

    #region 3D Drawing

    public static void DrawLine3D(Vector3 from, Vector3 to, Color? color = null)
    {
        if (!_debugEnabled || _immediateMesh == null) return;

        var c = color ?? Colors.White;

        _immediateMesh.SurfaceBegin(Mesh.PrimitiveType.Lines);
        _immediateMesh.SurfaceSetColor(c);
        _immediateMesh.SurfaceAddVertex(from);
        _immediateMesh.SurfaceAddVertex(to);
        _immediateMesh.SurfaceEnd();
    }

    public static void DrawPoint3D(Vector3 position, float size = 0.1f, Color? color = null)
    {
        if (!_debugEnabled || _immediateMesh == null) return;

        var c = color ?? Colors.White;
        var half = size * 0.5f;

        DrawLine3D(position - new Vector3(half, 0, 0), position + new Vector3(half, 0, 0), c);
        DrawLine3D(position - new Vector3(0, half, 0), position + new Vector3(0, half, 0), c);
        DrawLine3D(position - new Vector3(0, 0, half), position + new Vector3(0, 0, half), c);
    }

    public static void DrawVector3D(Vector3 origin, Vector3 direction, Color? color = null, float arrowSize = 0.1f)
    {
        if (!_debugEnabled || _immediateMesh == null) return;

        var c = color ?? Colors.Green;
        var end = origin + direction;
        DrawLine3D(origin, end, c);

        if (direction.Length() > 0.01f)
        {
            var right = direction.Cross(Vector3.Up).Normalized() * arrowSize;
            if (right.IsZeroApprox())
                right = direction.Cross(Vector3.Right).Normalized() * arrowSize;

            var back = -direction.Normalized() * arrowSize;

            DrawLine3D(end, end + back + right, c);
            DrawLine3D(end, end + back - right, c);
        }
    }

    public static void DrawSphere3D(Vector3 center, float radius, Color? color = null, int segments = 16)
    {
        if (!_debugEnabled || _immediateMesh == null) return;

        var c = color ?? Colors.White;

        for (var i = 0; i < segments; i++)
        {
            var angle1 = (float)i / segments * Mathf.Tau;
            var angle2 = (float)(i + 1) / segments * Mathf.Tau;

            // XY plane
            var p1 = center + new Vector3(Mathf.Cos(angle1), Mathf.Sin(angle1), 0) * radius;
            var p2 = center + new Vector3(Mathf.Cos(angle2), Mathf.Sin(angle2), 0) * radius;
            DrawLine3D(p1, p2, c);

            // XZ plane
            p1 = center + new Vector3(Mathf.Cos(angle1), 0, Mathf.Sin(angle1)) * radius;
            p2 = center + new Vector3(Mathf.Cos(angle2), 0, Mathf.Sin(angle2)) * radius;
            DrawLine3D(p1, p2, c);

            // YZ plane
            p1 = center + new Vector3(0, Mathf.Cos(angle1), Mathf.Sin(angle1)) * radius;
            p2 = center + new Vector3(0, Mathf.Cos(angle2), Mathf.Sin(angle2)) * radius;
            DrawLine3D(p1, p2, c);
        }
    }

    public static void DrawAabb3D(Aabb aabb, Color? color = null)
    {
        if (!_debugEnabled || _immediateMesh == null) return;

        var c = color ?? Colors.White;
        var pos = aabb.Position;
        var size = aabb.Size;

        Vector3[] corners =
        {
            pos,
            pos + new Vector3(size.X, 0, 0),
            pos + new Vector3(size.X, 0, size.Z),
            pos + new Vector3(0, 0, size.Z),
            pos + new Vector3(0, size.Y, 0),
            pos + new Vector3(size.X, size.Y, 0),
            pos + size,
            pos + new Vector3(0, size.Y, size.Z)
        };

        // Bottom face
        DrawLine3D(corners[0], corners[1], c);
        DrawLine3D(corners[1], corners[2], c);
        DrawLine3D(corners[2], corners[3], c);
        DrawLine3D(corners[3], corners[0], c);

        // Top face
        DrawLine3D(corners[4], corners[5], c);
        DrawLine3D(corners[5], corners[6], c);
        DrawLine3D(corners[6], corners[7], c);
        DrawLine3D(corners[7], corners[4], c);

        // Vertical edges
        DrawLine3D(corners[0], corners[4], c);
        DrawLine3D(corners[1], corners[5], c);
        DrawLine3D(corners[2], corners[6], c);
        DrawLine3D(corners[3], corners[7], c);
    }

    #endregion

    #region Logging

    public static void LogInfo(string message)
    {
        if (_debugEnabled)
            GD.Print($"[{Time.GetTimeStringFromSystem()}] {message}");
    }

    public static void LogWarn(string message)
    {
        if (_debugEnabled)
            GD.PushWarning($"[{Time.GetTimeStringFromSystem()}] {message}");
    }

    public static void LogError(string message)
    {
        GD.PushError($"[{Time.GetTimeStringFromSystem()}] {message}");
    }

    public static void LogPhysicsState(RigidBody3D body)
    {
        if (!_debugEnabled) return;

        GD.Print($"=== Physics State: {body.Name} ===");
        GD.Print($"  Position: {body.GlobalPosition}");
        GD.Print($"  Velocity: {body.LinearVelocity} ({body.LinearVelocity.Length():F2} m/s)");
        GD.Print($"  Angular:  {body.AngularVelocity}");
        GD.Print($"  Mass:     {body.Mass:F2} kg");
    }

    #endregion
}
