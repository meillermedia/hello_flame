import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:tiled/tiled.dart';

late TiledComponent tiles;
late SpriteAnimation leftChicken, rightChicken, upChicken, downChicken, chicken;
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  tiles = await TiledComponent.load('maze.tmx', Vector2.all(32));

  leftChicken = await SpriteAnimation.load(
      'chicken.png',
      SpriteAnimationData.sequenced(
          texturePosition: Vector2(0, 0),
          amount: 2,
          stepTime: 1,
          textureSize: Vector2(32, 32)));
  rightChicken = await SpriteAnimation.load(
      'chicken.png',
      SpriteAnimationData.sequenced(
          texturePosition: Vector2(2 * 32, 0),
          amount: 2,
          stepTime: 1,
          textureSize: Vector2(32, 32)));
  upChicken = await SpriteAnimation.load(
      'chicken.png',
      SpriteAnimationData.sequenced(
          texturePosition: Vector2(2 * 32, 32),
          amount: 2,
          stepTime: 1,
          textureSize: Vector2(32, 32)));
  downChicken = await SpriteAnimation.load(
      'chicken.png',
      SpriteAnimationData.sequenced(
          texturePosition: Vector2(0, 32),
          amount: 2,
          stepTime: 1,
          textureSize: Vector2(32, 32)));
  chicken = downChicken;
  runApp(GameWidget(game: MyGame()));
}

class MyGame extends FlameGame with TapDetector {
  late Vector2 pos;
  late int score;
  TextPaint textPaint = TextPaint(style: const TextStyle(fontFamily: 'Arial'));

  MyGame() {
    pos = Vector2(1, 1);
    score = 0;
  }
  @override
  Future<void> onLoad() async {
    add(tiles);
    await loadGrain();
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    chicken.getSprite().render(canvas, position: pos * 32);
    textPaint.render(canvas, "Score: $score", Vector2(10, 10));
  }

  @override
  void onTapDown(TapDownInfo info) {
    var tl = tiles.tileMap.map.layers[0] as TileLayer;
    var p = info.eventPosition.viewport;
    var chpos = pos * 32 + Vector2(16, 16);
    var diff = p - chpos;
    var tileData = tl.tileData;

    if (tileData != null) {
      if (diff.x.abs() > diff.y.abs()) {
        // horiz.
        if (diff.x > 0) {
          // right
          if (tileData[pos.y.floor()][pos.x.floor() + 1].tile < 4) {
            pos.x += 1;
            chicken = leftChicken;
            chicken.update(1);
          }
        } else {
          // left
          if (tileData[pos.y.floor()][pos.x.floor() - 1].tile < 4) {
            pos.x -= 1;
            chicken = rightChicken;
            chicken.update(1);
          }
        }
      } else {
        // vert
        if (diff.y > 0) {
          // down
          if (tileData[pos.y.floor() + 1][pos.x.floor()].tile < 4) {
            pos.y += 1;
            chicken = downChicken;
            chicken.update(1);
          }
        } else {
          // up
          if (tileData[pos.y.floor() - 1][pos.x.floor()].tile < 4) {
            pos.y -= 1;
            chicken = upChicken;
            chicken.update(1);
          }
        }
      }
    }
    //Remove from same position
    for (var gr in children) {
      if (gr is Grain &&
          gr.tileX == pos.x && gr.tileY == pos.y) {
        children.remove(gr);
        score++;
        break;
      }
    }
  }

  Future<void> loadGrain() async {
    var batches = tiles.tileMap.batches['grain.png'];
    //final img = await Flame.images.load('grain.png');
    var layer = tiles.tileMap.map.layers[1] as TileLayer; // Grain
    var tileData = layer.tileData;
    if (tileData != null && batches != null) {
      batches.clear(); //Remove from map
      //Add as components
      for (int y = 0; y < tileData.length; y++) {
        for (int x = 0; x < tileData[y].length; x++) {
          if (tileData[y][x].tile > 0) {
            add(Grain.fromImage(x, y, batches.atlas,
                srcPosition: Vector2(0, 0),
                srcSize: Vector2(32, 32),
                position: Vector2(x * 32, y * 32)));
          }
        }
      }
    }
  }
}
//Grain with tile position
class Grain extends SpriteComponent {
  late int tileX, tileY;
  Grain.fromImage(this.tileX, this.tileY, img, 
      {required srcPosition, required srcSize, required position})
      : super.fromImage(img, srcPosition: srcPosition, srcSize: srcSize, position: position);
}
