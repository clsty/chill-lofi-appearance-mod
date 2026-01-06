# 在 Debian 13 下测试通过。需要安装依赖以提供 xbuild（假如能安装 msbuild 则更好，但 Debian 13 未提供 msbuild）
# sudo apt install -y make mono-complete

# --- 路径配置 ---
# 游戏根目录
GAME_ROOT ?= $(HOME)/.steam/steam/steamapps/common/Chill with You Lo-Fi Story

# --- 编译配置 ---
CONFIGURATION = Release
# 优先使用 msbuild，若无则回退到 xbuild
BUILDER := $(shell command -v msbuild 2>/dev/null || command -v xbuild 2>/dev/null)
# 原始项目文件名
ORIGINAL_PROJ = Cavi.ChillWithAnyone.csproj
# 临时包装文件名
WRAPPER_PROJ = src/Cavi.ChillWithAnyone.csproj.temp
NETSTANDARD_DLL = /usr/lib/mono/4.7.2-api/Facades/netstandard.dll

.PHONY: all build clean check-path install-system-deps

all: build

check-path:
	@if [ ! -d "$(GAME_ROOT)" ]; then \
		echo "错误: 找不到游戏目录:"; \
		echo "  $(GAME_ROOT)"; \
		echo "你可以通过命令指定路径: make GAME_ROOT='/your/custom/path'"; \
		exit 1; \
	fi
	@if [ ! -d "$(GAME_ROOT)/Chill With You_Data/Managed" ]; then \
		echo "错误: 找不到 Managed 目录:"; \
		echo "  $(GAME_ROOT)/Chill With You_Data/Managed"; \
		echo "你可能需要验证游戏文件完整性或重装游戏"; \
		exit 1; \
	fi
	@echo "已找到游戏路径: $(GAME_ROOT)"

gen-wrapper:
	@echo '<Project ToolsVersion="15.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">' > $(WRAPPER_PROJ)
	@echo '  <Import Project="$(ORIGINAL_PROJ)" />' >> $(WRAPPER_PROJ)
	@echo '  <ItemGroup>' >> $(WRAPPER_PROJ)
	@echo '    <Reference Include="netstandard">' >> $(WRAPPER_PROJ)
	@echo '      <HintPath>$(NETSTANDARD_DLL)</HintPath>' >> $(WRAPPER_PROJ)
	@echo '    </Reference>' >> $(WRAPPER_PROJ)
	@echo '  </ItemGroup>' >> $(WRAPPER_PROJ)
	@echo '</Project>' >> $(WRAPPER_PROJ)

build: check-path gen-wrapper
	$(BUILDER) $(WRAPPER_PROJ) \
		/p:Configuration=$(CONFIGURATION) \
		/p:GamePath="$(GAME_ROOT)"
	@rm $(WRAPPER_PROJ)

clean:
	rm -rf src/bin/ src/obj/
	rm -f extra.targets
