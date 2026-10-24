# SPDX-FileCopyrightText: 2026 Dean Henny Anton Lemans <deanlemans@mailbox.org>
# SPDX-License-Identifier: EUPL-1.2
class_name InputFrame
extends RefCounted

var move: Vector2
var axis: float
var run: bool
var jump_pressed: bool
var jump_released: bool
var crouch: bool
var dash_pressed: bool
var interact_pressed: bool
