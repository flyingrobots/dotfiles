FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install test dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    zsh \
    git \
    tmux \
    curl \
    python3 \
    bats \
    neovim \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root test user
RUN useradd -m -s /bin/zsh testuser

USER testuser
WORKDIR /home/testuser/dotfiles

# Copy dotfiles repository
COPY --chown=testuser:testuser . .

# Default test command
CMD ["bats", "tests/"]
