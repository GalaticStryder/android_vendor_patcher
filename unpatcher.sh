#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2018 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
#

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
PATCH_ROOT="${SELF%/*}/patches"
SOURCE_ROOT="${SELF%/*}/../.."

while read -r PATCH_DIR; do
	[[ -n $PATCH_DIR && -d $PATCH_DIR/.git ]] || continue
	git -C "$PATCH_DIR" clean -dfqx
	git -C "$PATCH_DIR" reset -q --hard
done < <(find "$PATCH_ROOT" -type d -printf '%P\n')
