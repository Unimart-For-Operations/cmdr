# K9s — Kubernetes TUI configuration
# Theme: Catppuccin Frappe (sourced from _shared/theme)
{ hostMeta ? { }, ... }:

let
  # Allow host-level override via hostMeta.theme, fall back to the
  # repository default theme name for backward compatibility.
  theme = (import ../../../_shared/theme).call (if builtins.hasAttr "theme" hostMeta then hostMeta.theme else "catppuccin-frappe");
  p = theme.palette;
in
{
  programs.k9s = {
    enable = true;

    settings = {
      k9s = {
        liveViewAutoRefresh = false;
        screenDumpDir = "~/.local/state/k9s/screen-dumps";
        refreshRate = 2;
        maxConnRetry = 5;
        readOnly = false;
        noExitOnCtrlC = false;
        portForwardAddress = "localhost";
        ui = {
          enableMouse = false;
          headless = false;
          logoless = false;
          crumbsless = false;
          reactive = false;
          noIcons = false;
          defaultsToFullScreen = false;
          # skin name auto-set by HM from programs.k9s.skins key
        };
        skipLatestRevCheck = false;
        disablePodCounting = false;
        shellPod = {
          image = "busybox:1.35.0";
          namespace = "default";
          limits = {
            cpu = "100m";
            memory = "100Mi";
          };
        };
        imageScans = {
          enable = false;
          exclusions = {
            namespaces = [ ];
            labels = { };
          };
        };
        logger = {
          tail = 100;
          buffer = 5000;
          sinceSeconds = -1;
          textWrap = false;
          disableAutoscroll = false;
          showTime = false;
        };
        thresholds = {
          cpu = {
            critical = 90;
            warn = 70;
          };
          memory = {
            critical = 90;
            warn = 70;
          };
        };
      };
    };

    aliases = {
      aliases = {
        dp = "deployments";
        sec = "v1/secrets";
        jo = "jobs";
        cr = "clusterroles";
        crb = "clusterrolebindings";
        ro = "roles";
        rb = "rolebindings";
        np = "networkpolicies";
      };
    };

    skins = {
      "${theme.toolThemes.k9s}" = {
        k9s = {
          body = {
            fgColor = p.text;
            bgColor = p.base;
            logoColor = p.mauve;
          };
          prompt = {
            fgColor = p.text;
            bgColor = p.mantle;
            suggestColor = p.blue;
          };
          help = {
            fgColor = p.text;
            bgColor = p.base;
            sectionColor = p.green;
            keyColor = p.blue;
            numKeyColor = p.maroon;
          };
          frame = {
            title = {
              fgColor = p.teal;
              bgColor = p.base;
              highlightColor = p.pink;
              counterColor = p.yellow;
              filterColor = p.green;
            };
            border = {
              fgColor = p.mauve;
              focusColor = p.lavender;
            };
            menu = {
              fgColor = p.text;
              keyColor = p.blue;
              numKeyColor = p.maroon;
            };
            crumbs = {
              fgColor = p.base;
              bgColor = p.maroon;
              activeColor = p.flamingo;
            };
            status = {
              newColor = p.blue;
              modifyColor = p.lavender;
              addColor = p.green;
              pendingColor = p.peach;
              errorColor = p.red;
              highlightColor = p.sky;
              killColor = p.mauve;
              completedColor = p.overlay0;
            };
          };
          info = {
            fgColor = p.peach;
            sectionColor = p.text;
          };
          views = {
            table = {
              fgColor = p.text;
              bgColor = p.base;
              cursorFgColor = p.surface0;
              cursorBgColor = p.surface1;
              markColor = p.rosewater;
              header = {
                fgColor = p.yellow;
                bgColor = p.base;
                sorterColor = p.sky;
              };
            };
            xray = {
              fgColor = p.text;
              bgColor = p.base;
              cursorColor = p.surface1;
              cursorTextColor = p.base;
              graphicColor = p.pink;
            };
            charts = {
              bgColor = p.base;
              chartBgColor = p.base;
              dialBgColor = p.base;
              defaultDialColors = [ p.green p.red ];
              defaultChartColors = [ p.green p.red ];
              resourceColors = {
                cpu = [ p.mauve p.blue ];
                mem = [ p.yellow p.peach ];
              };
            };
            yaml = {
              keyColor = p.blue;
              valueColor = p.text;
              colonColor = p.subtext0;
            };
            logs = {
              fgColor = p.text;
              bgColor = p.base;
              indicator = {
                fgColor = p.lavender;
                bgColor = p.base;
                toggleOnColor = p.green;
                toggleOffColor = p.subtext0;
              };
            };
          };
          dialog = {
            fgColor = p.yellow;
            bgColor = p.overlay2;
            buttonFgColor = p.base;
            buttonBgColor = p.overlay1;
            buttonFocusFgColor = p.base;
            buttonFocusBgColor = p.pink;
            labelFgColor = p.rosewater;
            fieldFgColor = p.text;
          };
        };
      };
    };
  };
}
