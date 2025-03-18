echo "############### 01_dependencies.sh ###############"
echo "🚀 Installing dependencies..."

# Detect OS
OS=$(uname -s)

echo "🔍 Detecting OS..."
if [[ "$OS" == "Linux" ]]; then
  echo "✅ Linux detected."
  PKG_MANAGER=$(command -v apt || command -v yum || echo "unknown")
  PROFILE_FILE="$HOME/.bashrc"
elif [[ "$OS" == "Darwin" ]]; then
  echo "✅ macOS detected."
  PKG_MANAGER="brew"
  PROFILE_FILE="$HOME/.zshrc"
else
  echo "❌ Unsupported OS: $OS"
  exit 1
fi

# Install Homebrew on macOS if not installed
if [[ "$OS" == "Darwin" ]] && ! command -v brew &>/dev/null; then
  echo "🔹 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install `krew`
if ! command -v kubectl-krew &>/dev/null; then
  echo "🔹 Installing krew..."
  (
    set -x
    cd "$(mktemp -d)" &&
    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
    ARCH="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')" &&
    KREW="krew-${OS}_${ARCH}" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
    tar zxvf "${KREW}.tar.gz" &&
    ./"${KREW}" install krew
  )
fi

# Ensure krew is in PATH
KREW_PATH='export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"'

# Add to the correct profile file only if it's missing
if ! grep -qxF "$KREW_PATH" "$PROFILE_FILE"; then
  echo "$KREW_PATH" >> "$PROFILE_FILE"
  echo "🔹 Added Krew path to $PROFILE_FILE"
  source "$PROFILE_FILE"
else
  echo "✅ Krew path already exists in $PROFILE_FILE"
fi

# Install kubectl
if ! command -v kubectl &>/dev/null; then
  echo "🔹 Installing kubectl..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install kubectl
  elif [[ "$PKG_MANAGER" == "apt" ]]; then
    sudo apt update && sudo apt install -y kubectl
  elif [[ "$PKG_MANAGER" == "yum" ]]; then
    sudo yum install -y kubectl
  else
    echo "❌ Package manager not supported!"
    exit 1
  fi
fi

# Install `oidc-login` for kubectl
echo "🔹 Installing kubectl oidc-login..."
kubectl krew uninstall oidc-login || true  # If already installed, remove it first
kubectl krew install oidc-login

# Verify oidc-login
kubectl oidc-login version || echo "❌ OIDC Login plugin installation failed!"

# Install Azure CLI
if ! command -v az &>/dev/null; then
  echo "🔹 Installing Azure CLI..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install azure-cli
  elif [[ "$PKG_MANAGER" == "apt" ]]; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  elif [[ "$PKG_MANAGER" == "yum" ]]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
    sudo yum install -y azure-cli
  else
    echo "❌ Package manager not supported!"
    exit 1
  fi
fi

# Install `kind`
if ! command -v kind &>/dev/null; then
  echo "🔹 Installing kind..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install kind
  elif [[ "$PKG_MANAGER" == "apt" ]]; then
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64"
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
  elif [[ "$PKG_MANAGER" == "yum" ]]; then
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64"
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
  else
    echo "❌ Package manager not supported!"
    exit 1
  fi
fi

echo "✅ Dependencies are installed and ready to use!"
# Inform the user
echo "⚡ Restart your terminal or run: source $PROFILE_FILE"