# MyNixOSConfig

这套配置参考了 [Flakes aren't real and cannot hurt you](https://jade.fyi/blog/flakes-arent-real/)
的组织方式：flake 负责依赖锁定和标准入口，内部用普通 Nix 函数、模块、
`callPackage` 和包集合组合。

## 文件结构

- `flake.nix` / `flake.lock`：声明并锁定求值所需的外部 Nix 代码。
- `outputs.nix`：创建共享 `pkgs`，集中设置 `allowUnfree`、Rust 和静态 CJK 字体 overlay，
  通过 `nixpkgs.pkgs = pkgs` 交给 NixOS，提供系统、formatter 和本地包的 flake 输出。
- `nixos.nix`：通过函数参数和词法闭包连接外部 NixOS / Home Manager 模块，
  注入 Home Manager 所需的外部依赖。
- `configuration.nix`、`hardware-configuration.nix`、`nix-ld.nix`：
  普通模块，不接收整个 flake `inputs`。
- `home.nix`：接收 `llm-agents` 依赖并返回 Home Manager 模块，在 `home.packages`
  中直接引用和安装其中的 `dsh` 包。
- `packages/default.nix`：用 `callPackage` 定义普通属性集，集中提供本地包。

外部依赖只在连接层使用，不通过 `specialArgs` 或 `extraSpecialArgs` 传给所有模块。
Home Manager 继续使用系统的 `pkgs`。`llm-agents` 的 `dsh` 保留上游自己的包集合和锁定，
避免因强制统一 nixpkgs 而改变其构建依赖。

系统使用外部创建的 `pkgs`，因此 `allowUnfree` 等 nixpkgs 配置应在 `outputs.nix`
的 `import nixpkgs` 参数中设置，不再通过 NixOS 的 `nixpkgs.config` 重复设置。

本地包通过单独的局部变量 `localPkgs = pkgs.callPackage ./packages { };` 引用
可以按以下方式分别引用包：

```nix
(with pkgs; [ git ripgrep ])
++ (with localPkgs; [ ab-download-manager wpsoffice ])
```

## 日常操作

```sh
nix fmt
nix flake check --no-build
nh os switch .
```

新增 Nix 文件后，先用 `git add <文件路径>` 将它们纳入 Git；本地 Git flake 只读取已跟踪文件。
`rebuild` 别名仍然会格式化并通过 `nh` 切换系统。

本地包也可以单独构建：

```sh
nix build .#ab-download-manager
nix build .#clice
nix build .#personal-fonts
nix build .#wpsoffice
```

## 不通过 flake 复用本地包

包集合不依赖 flakes；可以直接用调用方提供的 nixpkgs 实例化：

```nix
let
  pkgs = import <nixpkgs> {
    config.allowUnfree = true;
  };
  localPkgs = pkgs.callPackage ./packages { };
in
localPkgs.ab-download-manager
```

也可以直接调用单个包定义，例如 `pkgs.callPackage ./packages/clice.nix { }`。
单个包支持通常的 `override` / `overrideAttrs`。
预编译的 x86_64 软件的平台支持仍取决于各包定义。

构建时才需要的源码、归档和二进制继续使用包内的固定哈希 fetcher，
无需添加为 flake input。当前锁定的 NixOS 已自动配置 nixpkgs registry 和 `NIX_PATH`，
因此 `<nixpkgs>` 与系统使用同一份 nixpkgs，关闭 channels 后也可使用传统入口。

依赖版本仍由 `flake.lock` 管理。本次结构重构没有更新依赖；nixpkgs 继续固定到
保留 Plasma X11 会话的版本。
