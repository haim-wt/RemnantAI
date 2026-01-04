using Godot;
using Godot.Collections;
using Remnant.Autoloads;

namespace Remnant.UI;

/// <summary>
/// 2D cockpit HUD overlay - always visible on screen.
/// </summary>
public partial class Cockpit : CanvasLayer
{
    #region Exports

    [ExportGroup("References")]
    [Export] public RigidBody3D? TargetShip { get; set; }

    [ExportGroup("Colors")]
    [Export] public Color DisplayColor { get; set; } = new(0.2f, 0.9f, 1.0f);
    [Export] public Color WarningColor { get; set; } = new(1.0f, 0.8f, 0.2f);
    [Export] public Color CriticalColor { get; set; } = new(1.0f, 0.3f, 0.2f);
    [Export] public Color OnTargetColor { get; set; } = new(0.2f, 1.0f, 0.4f);

    #endregion

    #region State

    private Dictionary _currentData = new();
    private bool _isFirstPerson;

    private Label? _speedDisplay;
    private Label? _targetSpeedDisplay;
    private Label? _statusDisplay;
    private Control? _reticle;
    private Control? _thrusterIndicator;
    private Control? _hudContainer;

    // 3D hologram components
    private SubViewport? _hologramViewport;
    private MeshInstance3D? _hologramShip;
    private Camera3D? _hologramCamera;

    // Thruster indicator settings
    private const float ThrusterIndicatorSize = 20f;
    private const float IndicatorFov = 90f; // Degrees - how much of the sphere maps to screen

    // Hologram settings
    private const int HologramSize = 120; // Viewport size in pixels

    #endregion

    public override void _Ready()
    {
        Events.Instance.HudUpdateRequested += OnHudUpdateRequested;
        Events.Instance.CameraModeChanged += OnCameraModeChanged;
        BuildCockpit();
        Visible = false;
    }

    public override void _Process(double delta)
    {
        UpdateDisplays();
    }

    #region Cockpit Construction

    private void BuildCockpit()
    {
        // Create a Control node to hold 2D HUD elements
        _hudContainer = new Control();
        _hudContainer.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        AddChild(_hudContainer);

        // Create center reticle
        BuildReticle(_hudContainer);

        // Create thruster indicator (ship orientation reference)
        BuildThrusterIndicator(_hudContainer);

        // Create bottom panel for dashboard
        var bottomPanel = new Panel();
        bottomPanel.SetAnchorsPreset(Control.LayoutPreset.BottomWide);
        bottomPanel.OffsetTop = -120;
        bottomPanel.OffsetBottom = -10;
        bottomPanel.OffsetLeft = 100;
        bottomPanel.OffsetRight = -100;

        // Style the panel
        var panelStyle = new StyleBoxFlat
        {
            BgColor = new Color(0.05f, 0.05f, 0.08f, 0.85f),
            BorderColor = new Color(0.2f, 0.3f, 0.4f)
        };
        panelStyle.SetBorderWidthAll(2);
        panelStyle.SetCornerRadiusAll(4);
        bottomPanel.AddThemeStyleboxOverride("panel", panelStyle);
        _hudContainer.AddChild(bottomPanel);

        // Create HBoxContainer for layout
        var hbox = new HBoxContainer();
        hbox.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        hbox.OffsetLeft = 20;
        hbox.OffsetRight = -20;
        hbox.OffsetTop = 10;
        hbox.OffsetBottom = -10;
        hbox.Alignment = BoxContainer.AlignmentMode.Center;
        hbox.AddThemeConstantOverride("separation", 80);
        bottomPanel.AddChild(hbox);

        // Speed display (left)
        var speedContainer = new VBoxContainer
        {
            Alignment = BoxContainer.AlignmentMode.Center,
            SizeFlagsVertical = Control.SizeFlags.ShrinkCenter
        };
        hbox.AddChild(speedContainer);

        _speedDisplay = new Label
        {
            Text = "000",
            HorizontalAlignment = HorizontalAlignment.Center
        };
        _speedDisplay.AddThemeFontSizeOverride("font_size", 36);
        _speedDisplay.AddThemeColorOverride("font_color", DisplayColor);
        speedContainer.AddChild(_speedDisplay);

        var speedLabel = new Label
        {
            Text = "M/S",
            HorizontalAlignment = HorizontalAlignment.Center
        };
        speedLabel.AddThemeFontSizeOverride("font_size", 12);
        speedLabel.AddThemeColorOverride("font_color", new Color(0.5f, 0.6f, 0.7f));
        speedContainer.AddChild(speedLabel);

        // Target speed display (center)
        var targetContainer = new VBoxContainer
        {
            Alignment = BoxContainer.AlignmentMode.Center,
            SizeFlagsVertical = Control.SizeFlags.ShrinkCenter
        };
        hbox.AddChild(targetContainer);

        _targetSpeedDisplay = new Label
        {
            Text = "TGT 000",
            HorizontalAlignment = HorizontalAlignment.Center
        };
        _targetSpeedDisplay.AddThemeFontSizeOverride("font_size", 36);
        _targetSpeedDisplay.AddThemeColorOverride("font_color", new Color(0.6f, 0.8f, 0.9f));
        targetContainer.AddChild(_targetSpeedDisplay);

        var targetLabel = new Label
        {
            Text = "TARGET",
            HorizontalAlignment = HorizontalAlignment.Center
        };
        targetLabel.AddThemeFontSizeOverride("font_size", 12);
        targetLabel.AddThemeColorOverride("font_color", new Color(0.4f, 0.5f, 0.6f));
        targetContainer.AddChild(targetLabel);

        // 3D Hologram display (center-right)
        var hologramContainer = new VBoxContainer
        {
            Alignment = BoxContainer.AlignmentMode.Center,
            SizeFlagsVertical = Control.SizeFlags.ShrinkCenter
        };
        hbox.AddChild(hologramContainer);

        BuildHologramDisplay(hologramContainer);

        var hologramLabel = new Label
        {
            Text = "ATTITUDE",
            HorizontalAlignment = HorizontalAlignment.Center
        };
        hologramLabel.AddThemeFontSizeOverride("font_size", 12);
        hologramLabel.AddThemeColorOverride("font_color", new Color(0.4f, 0.5f, 0.6f));
        hologramContainer.AddChild(hologramLabel);

        // Status display (right)
        var statusContainer = new VBoxContainer
        {
            Alignment = BoxContainer.AlignmentMode.Center,
            SizeFlagsVertical = Control.SizeFlags.ShrinkCenter
        };
        hbox.AddChild(statusContainer);

        _statusDisplay = new Label
        {
            Text = "LOCK",
            HorizontalAlignment = HorizontalAlignment.Center
        };
        _statusDisplay.AddThemeFontSizeOverride("font_size", 36);
        _statusDisplay.AddThemeColorOverride("font_color", OnTargetColor);
        statusContainer.AddChild(_statusDisplay);

        var statusLabel = new Label
        {
            Text = "STATUS",
            HorizontalAlignment = HorizontalAlignment.Center
        };
        statusLabel.AddThemeFontSizeOverride("font_size", 12);
        statusLabel.AddThemeColorOverride("font_color", new Color(0.4f, 0.5f, 0.6f));
        statusContainer.AddChild(statusLabel);
    }

    private void BuildHologramDisplay(Control parent)
    {
        // Create SubViewportContainer to display the 3D viewport
        var viewportContainer = new SubViewportContainer
        {
            CustomMinimumSize = new Vector2(100, 80),
            StretchShrink = 1,
            Stretch = true
        };
        parent.AddChild(viewportContainer);

        // Create SubViewport with its own isolated World3D
        _hologramViewport = new SubViewport
        {
            Size = new Vector2I(100, 80),
            TransparentBg = true,
            RenderTargetUpdateMode = SubViewport.UpdateMode.Always,
            OwnWorld3D = true // Critical: isolate from main world
        };
        viewportContainer.AddChild(_hologramViewport);

        // Create camera for the hologram view - must be added and set as current
        _hologramCamera = new Camera3D
        {
            Position = new Vector3(0, 0.5f, 3f),
            RotationDegrees = new Vector3(-10, 0, 0),
            Fov = 40f,
            Current = true
        };
        _hologramViewport.AddChild(_hologramCamera);

        // Create holographic ship mesh
        _hologramShip = new MeshInstance3D
        {
            Position = Vector3.Zero
        };
        var boxMesh = new BoxMesh { Size = new Vector3(1.0f, 0.5f, 2.0f) };
        _hologramShip.Mesh = boxMesh;

        // Create holographic material - bright unshaded for visibility
        var holoMaterial = new StandardMaterial3D
        {
            AlbedoColor = new Color(0.3f, 0.9f, 1.0f, 1.0f),
            EmissionEnabled = true,
            Emission = new Color(0.2f, 0.7f, 1.0f),
            EmissionEnergyMultiplier = 3.0f,
            ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded
        };
        _hologramShip.MaterialOverride = holoMaterial;
        _hologramViewport.AddChild(_hologramShip);
    }

    private void BuildReticle(Control parent)
    {
        // Create a container centered on screen
        _reticle = new Control
        {
            CustomMinimumSize = new Vector2(40, 40)
        };
        _reticle.SetAnchorsPreset(Control.LayoutPreset.Center);
        _reticle.Position = new Vector2(-20, -20); // Center the 40x40 reticle
        parent.AddChild(_reticle);

        // Draw reticle using a simple cross pattern with ColorRect elements
        var lineThickness = 2f;
        var lineLength = 12f;

        // Top line
        var topLine = new ColorRect
        {
            Color = DisplayColor,
            Size = new Vector2(lineThickness, lineLength),
            Position = new Vector2(20 - lineThickness / 2, 0)
        };
        _reticle.AddChild(topLine);

        // Bottom line
        var bottomLine = new ColorRect
        {
            Color = DisplayColor,
            Size = new Vector2(lineThickness, lineLength),
            Position = new Vector2(20 - lineThickness / 2, 40 - lineLength)
        };
        _reticle.AddChild(bottomLine);

        // Left line
        var leftLine = new ColorRect
        {
            Color = DisplayColor,
            Size = new Vector2(lineLength, lineThickness),
            Position = new Vector2(0, 20 - lineThickness / 2)
        };
        _reticle.AddChild(leftLine);

        // Right line
        var rightLine = new ColorRect
        {
            Color = DisplayColor,
            Size = new Vector2(lineLength, lineThickness),
            Position = new Vector2(40 - lineLength, 20 - lineThickness / 2)
        };
        _reticle.AddChild(rightLine);

        // Center dot
        var centerDot = new ColorRect
        {
            Color = DisplayColor,
            Size = new Vector2(4, 4),
            Position = new Vector2(18, 18)
        };
        _reticle.AddChild(centerDot);
    }

    private void BuildThrusterIndicator(Control parent)
    {
        // Create a container for the thruster indicator (represents ship's rear)
        _thrusterIndicator = new Control
        {
            CustomMinimumSize = new Vector2(ThrusterIndicatorSize, ThrusterIndicatorSize)
        };
        _thrusterIndicator.SetAnchorsPreset(Control.LayoutPreset.Center);
        parent.AddChild(_thrusterIndicator);

        var halfSize = ThrusterIndicatorSize / 2f;
        var ringThickness = 2f;

        // Draw a circle using 8 small rectangles arranged in an octagon pattern
        var segmentCount = 12;
        for (int i = 0; i < segmentCount; i++)
        {
            var angle = i * Mathf.Tau / segmentCount;
            var nextAngle = (i + 1) * Mathf.Tau / segmentCount;

            var x1 = halfSize + Mathf.Cos(angle) * (halfSize - ringThickness);
            var y1 = halfSize + Mathf.Sin(angle) * (halfSize - ringThickness);
            var x2 = halfSize + Mathf.Cos(nextAngle) * (halfSize - ringThickness);
            var y2 = halfSize + Mathf.Sin(nextAngle) * (halfSize - ringThickness);

            // Create a small line segment
            var segment = new ColorRect
            {
                Color = WarningColor,
                Size = new Vector2(3, 3),
                Position = new Vector2(x1 - 1.5f, y1 - 1.5f)
            };
            _thrusterIndicator.AddChild(segment);
        }
    }

    #endregion

    #region Display Updates

    private void OnHudUpdateRequested(Dictionary data)
    {
        _currentData = data;
    }

    private void OnCameraModeChanged(int mode)
    {
        _isFirstPerson = mode == 1;
        Visible = _isFirstPerson;
    }

    private void UpdateDisplays()
    {
        if (_currentData.Count == 0) return;

        // Update speed
        var speed = _currentData.TryGetValue("speed", out var s) ? s.AsSingle() : 0f;
        if (_speedDisplay != null)
        {
            _speedDisplay.Text = $"{(int)speed:D3}";

            var color = speed switch
            {
                > 250 => CriticalColor,
                > 150 => WarningColor,
                _ => DisplayColor
            };
            _speedDisplay.AddThemeColorOverride("font_color", color);
        }

        // Update target speed
        var targetSpeed = _currentData.TryGetValue("target_speed", out var ts) ? ts.AsSingle() : 0f;
        if (_targetSpeedDisplay != null)
        {
            _targetSpeedDisplay.Text = $"TGT {(int)targetSpeed:D3}";
        }

        // Update status
        var isManeuvering = _currentData.TryGetValue("is_maneuvering", out var m) && m.AsBool();
        if (_statusDisplay != null)
        {
            if (isManeuvering)
            {
                _statusDisplay.Text = "MNVR";
                _statusDisplay.AddThemeColorOverride("font_color", WarningColor);
            }
            else
            {
                _statusDisplay.Text = "LOCK";
                _statusDisplay.AddThemeColorOverride("font_color", OnTargetColor);
            }
        }

        // Update thruster indicator position
        UpdateThrusterIndicator();

        // Update hologram orientation
        UpdateHologram();
    }

    private void UpdateHologram()
    {
        if (_hologramShip == null) return;

        // Get ship and POV basis from HUD data
        if (!_currentData.TryGetValue("ship_basis", out var sbVar)) return;
        if (!_currentData.TryGetValue("pov_basis", out var pbVar)) return;

        // Basis is stored directly as Basis type in the dictionary
        var shipBasis = (Basis)sbVar;
        var povBasis = (Basis)pbVar;

        // Calculate relative rotation: ship orientation relative to POV
        // This shows how the ship is oriented compared to where you want to go
        var relativeBasis = povBasis.Inverse() * shipBasis;

        // Apply to hologram mesh
        _hologramShip.Transform = new Transform3D(relativeBasis, Vector3.Zero);
    }

    private void UpdateThrusterIndicator()
    {
        if (_thrusterIndicator == null || _hudContainer == null) return;

        // Get POV basis vectors and ship forward from HUD data
        var povForward = _currentData.TryGetValue("pov_forward", out var pf)
            ? pf.AsVector3()
            : -Vector3.ModelFront;
        var povRight = _currentData.TryGetValue("pov_right", out var pr)
            ? pr.AsVector3()
            : Vector3.Right;
        var povUp = _currentData.TryGetValue("pov_up", out var pu)
            ? pu.AsVector3()
            : Vector3.Up;
        var shipForward = _currentData.TryGetValue("ship_forward", out var sf)
            ? sf.AsVector3()
            : -Vector3.ModelFront;

        // Calculate the angle between POV forward and ship forward
        var dotForward = shipForward.Dot(povForward);

        // If ship is pointing behind us (dot < 0), the indicator should be at the edge
        // representing that it's "behind" the view
        if (dotForward < -0.01f)
        {
            // Ship is pointing backwards - show indicator at the edge of the "sphere"
            // Project to the edge in the direction of the ship
            var relativeX = shipForward.Dot(povRight);
            var relativeY = -shipForward.Dot(povUp);
            var edgeDir = new Vector2(relativeX, relativeY).Normalized();

            var screenSize = _hudContainer.GetViewportRect().Size;
            var center = screenSize / 2f;
            var maxRadius = Mathf.Min(screenSize.X, screenSize.Y) * 0.4f;

            _thrusterIndicator.Visible = true;
            _thrusterIndicator.Position = center + edgeDir * maxRadius - new Vector2(ThrusterIndicatorSize / 2f, ThrusterIndicatorSize / 2f);
            return;
        }

        // Ship is pointing forward - use spherical projection
        // Get the angular offset from center (in radians)
        var angleFromCenter = Mathf.Acos(Mathf.Clamp(dotForward, -1f, 1f));

        // Project ship forward onto POV's view plane
        var relX = shipForward.Dot(povRight);
        var relY = -shipForward.Dot(povUp); // Negative because screen Y is inverted

        // Normalize to get direction on screen
        var screenDir = new Vector2(relX, relY);
        if (screenDir.LengthSquared() > 0.0001f)
            screenDir = screenDir.Normalized();

        // Map angle to screen distance using tangent (proper perspective projection)
        // This maps the hemisphere to the screen
        var screenSize2 = _hudContainer.GetViewportRect().Size;
        var center2 = screenSize2 / 2f;
        var halfFovRad = Mathf.DegToRad(IndicatorFov / 2f);
        var maxScreenRadius = Mathf.Min(screenSize2.X, screenSize2.Y) * 0.4f;

        // tan(angle) / tan(halfFov) gives normalized distance from center
        var normalizedDist = Mathf.Tan(angleFromCenter) / Mathf.Tan(halfFovRad);
        var screenDist = normalizedDist * maxScreenRadius;

        // Clamp to screen bounds (circular)
        screenDist = Mathf.Min(screenDist, maxScreenRadius);

        _thrusterIndicator.Visible = true;
        _thrusterIndicator.Position = center2 + screenDir * screenDist - new Vector2(ThrusterIndicatorSize / 2f, ThrusterIndicatorSize / 2f);
    }

    #endregion
}
