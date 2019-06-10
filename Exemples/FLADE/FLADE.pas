unit FLADE;

{
  FlashPascal version of Flade - Flash Dynamics Engine
  (c)2013 Paul TOTH <contact@execute.re>
  http://flashpascal.execute.re

  WIP: 2013-11-10

  Flade is written and maintained by Alec Cove.
  http://www.cove.org/flade/
}

(**
 * Flade - Flash Dynamics Engine
 * Release 0.6 alpha
 * DynamicsEngine class
 * Copyright 2004, 2005 Alec Cove
 *
 * This file is part of Flade. The Flash Dynamics Engine.
 *
 * Flade is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Flade is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Flade; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * Flash is a registered trademark of Macromedia
 *)

interface

uses
  Flash8;

(**
 * class procedure are not supported for user defined classes yet
 * we can use procedure. NB: they can be put in a Graphics unit :)
 *)
{
type
  Graphics = class
    class procedure paintLine(dmc: MovieClip; x0, y0, x1, y1: Number);
    class procedure paintCircle(dmc: MovieClip; x, y, r: Number);
    class procedure paintRectangle(dmc: MovieClip; x, y, w, h: Number);
  end;
}
procedure paintLine(dmc: MovieClip; x0, y0, x1, y1: Number);
procedure paintCircle(dmc: MovieClip; x, y, r: Number);
procedure paintRectangle(dmc: MovieClip; x, y, w, h: Number);

type
  DynamicsEngine = class;
  Particle = class;
  CircleParticle = class;
  RectangleParticle = class;

  Vector = class
  public
    x : Number;
    y : Number;
    constructor Create(px, py: Number);
    procedure setTo(px, py: Number);
    procedure copy(v: Vector);
    function dot(v: Vector): Number;
    function cross(v: Vector): Number;
    function plus(v: Vector): Vector;
    function plusNew(v: Vector): Vector;
    function minus(v: Vector): Vector;
    function minusNew(v: Vector): Vector;
    function mult(s: Number): Vector;
    function multNew(s: Number): Vector;
    function distance(v: Vector): Number;
    function normalize(): Vector;
    function magnitude(): Number;
    function project(b: Vector): Vector;
  end;
  
  Line = class
  public
    p1: Vector;
    p2: Vector;
    constructor Create(p1, p2: Vector);
  end;
  
  Surface = class // should be an Interface
    procedure paint; virtual; abstract;
    
    function getActiveState: Boolean; virtual; abstract;
    procedure setActiveState(s: Boolean); virtual; abstract;
    
	  procedure resolveCircleCollision(p: CircleParticle; sysObj:DynamicsEngine); virtual; abstract;
	  procedure resolveRectangleCollision(p: RectangleParticle; sysObj:DynamicsEngine); virtual; abstract;
  end;
  
// TBD: need to clarify responsibilites between the Surface interface and the AbstractTile
  AbstractTile = class(Surface) // inherit from Surface cause it's not an Interface
  private
    minX        : Number;
    minY        : Number;
    maxX        : Number;
    maxY        : Number;
    verts       : TArray;
    
    center      : Vector;
    normal      : Vector;
    
    dmc         : MovieClip;
    isVisible   : Boolean;
    isActivated : Boolean;
  public
    constructor Create(cx, cy: Number);
    procedure initializeContainer;
    procedure setVisible(v: Boolean);
    procedure setActiveState(a: Boolean); override;
    function getActiveState: Boolean; override;
    procedure createBoundingRect(rw, rh: Number);
    function testIntervals(boxMin, boxMax, tileMin, tileMax: Number): Number;
    procedure setCardProjections;
    procedure getCardXProjection;
    procedure getCardYProjection;
    procedure onContact; virtual; abstract;
  end;
  
  //  TBD: this class should be replaced by a rotateable RectangleTile or Capsule (or both)
  LineSurface = class(AbstractTile) // implements Surface
  private
    p1             : Vector;
    p2             : Vector;
    p3             : Vector;
    p4             : Vector;
    faceNormal     : Vector;
    sideNormal     : Vector;
    collNormal     : Vector;
    
    rise           : Number;
    run            : Number;
    
    invB           : Number;
    sign           : Number;
    slope          : Number;
    
    minF           : Number;
    maxF           : Number;
    minS           : Number;
    maxS           : Number;
    collisionDepth : Number;
  public
    constructor Create(p1x, p1y, p2x, p2y: Number);
    procedure paint; override;
	  procedure resolveCircleCollision(p: CircleParticle; sysObj:DynamicsEngine); override;
	  procedure resolveRectangleCollision(p: RectangleParticle; sysObj:DynamicsEngine); override;
    procedure setCollisionDepth(d: Number);
  private
    function isCircleColliding(p: CircleParticle): Boolean;
    function isRectangleColliding(p: RectangleParticle): Boolean;
    procedure precalculate;
    procedure calcFaceNormal;
    function segmentInequality(toPoint: Vector): Boolean;
    function inequality(toPoint: Vector): Boolean;
    procedure findClosestPoint(toPoint, returnVect: Vector);
    function findU(p: Vector): Number;
    procedure createRectangle;
    procedure setAxisProjections;
    procedure calcSideNormal;
  end;
  
  RectangleTile = class(AbstractTile) // implements Surface
  private
    rectWidth  : Number;
    rectHeight : Number;
  public
    constructor Create(cx, cy, rw, rh: Number);
    procedure paint; override;
	  procedure resolveCircleCollision(p: CircleParticle; sysObj:DynamicsEngine); override;
	  procedure resolveRectangleCollision(p: RectangleParticle; sysObj:DynamicsEngine); override;
  private
    function isCircleColliding(p: CircleParticle): Boolean;
    function isRectangleColliding(p: RectangleParticle): Boolean;
    function sign(val: Number): Number;
  end;
  
  CircleTile = class(AbstractTile) // implements Surface
  private
    radius: Number;
  public
    constructor Create(cx, cy, r: Number);
    procedure paint; override;
	  procedure resolveCircleCollision(p: CircleParticle; sysObj:DynamicsEngine); override;
	  procedure resolveRectangleCollision(p: RectangleParticle; sysObj:DynamicsEngine); override;
  private
    function isCircleColliding(p: CircleParticle): Boolean;
    function isRectangleColliding(p: RectangleParticle): Boolean;
    function sign(val: Number): Number;
  end;
  
  Constraint = class // should be an Interface
    procedure paint; virtual; abstract;
    procedure resolve; virtual; abstract;
  end;
  
  AngularConstraint = class(Constraint)
  public
    targetTheta : Number;
  private
    pA          : Vector;
    pB          : Vector;
    pC          : Vector;
    pD          : Vector;

    lineA       : Line;
    lineB       : Line;
    lineC       : Line;
    
    stiffness   : Number;
  public
    constructor Create(p1, p2, p3: Particle);
    procedure resolve; override;
    procedure paint; override;
    procedure setStiffness(s: Number);
  private
    function calcTheta(pa, pb, pc: Vector): Number;
    function getCentroid: Vector;
  end;
  
  SpringConstraint = class(Constraint)
  private
    p1         : Particle;
    p2         : Particle;
    restLength : Number;
    tearLength : Number;
    
    color      : Number;
    stiffness  : Number;
    isVisible  : Boolean;

    dmc        : MovieClip;
  public
    constructor Create(p1, p2: Particle);
    procedure initializeContainer;
    procedure resolve; override;
    procedure setRestLength(r: Number);
    procedure setStiffness(s: Number);
    procedure setVisible(v: Boolean);
    procedure paint; override;
  end;
  
  Particle = class
  public
    curr     : Vector;
    prev     : Vector;
    bmin     : Number;
    bmax     : Number;
    mtd      : Vector;
  private
    init     : Vector;
    temp     : Vector;
    extents  : Vector;
    dmc      : MovieClip;
    isVisible: Boolean;
  public
    constructor Create(posX, posY: Number);
    procedure initializeContainer();
    procedure setVisible(v: Boolean);
    procedure verlet(sysObj: DynamicsEngine); virtual;
    procedure pin();
    procedure setPos(px, py:Number);
    procedure getCardXProjection();
    procedure getCardYProjection();
    procedure getAxisProjection(axis: Vector);
    procedure setMTD(depthX, depthY, depthN:Number; surfNormal:Vector);
    procedure setXYMTD(depthX, depthY: Number);
    procedure resolveCollision(normal: Vector; sysObj: DynamicsEngine); virtual;
    procedure paint(); virtual;
    procedure checkCollision(surface: Surface; sysObj: DynamicsEngine); virtual;
  end;
  
  CircleParticle = class(Particle)
  public
    radius        : Number;
    closestPoint  : Vector;
    contactRadius : Number;
    constructor Create(px, py, r: Number);
    procedure paint; override;
    procedure checkCollision(surface: Surface; sysObj: DynamicsEngine); override;
  end;
  
  // TBD: extends particle...or rename
  RimParticle = class
  public
    curr     : Vector;
    prev     : Vector;
    speed    : Number;
    vs       : Number;
  private
    wr       : Number;
    maxTorque: Number;
  public
    constructor Create(r, mt: Number);
    procedure verlet(sysObj: DynamicsEngine);
  end;
  
  Wheel = class(CircleParticle)
  public
    rp       : RimParticle;
  private
    coeffSlip: Number;
  public
    constructor Create(x, y, r: Number);
    procedure verlet(sysObj: DynamicsEngine); override;
    procedure resolveCollision(normal: Vector; sysObj: DynamicsEngine); override;
    procedure paint; override;
    procedure setTraction(t: Number);
  private
    procedure resolve(n: Vector);
  end;
  
  RectangleParticle = class(Particle)
  public
    width  : Number;
    height : Number;
    vertex : Vector;
    constructor Create(px, py, w, h: Number);
    procedure paint; override;
    procedure checkCollision(surface: Surface; sysObj: DynamicsEngine); override;
  end;
  
  SpringBox = class
  public
    p0 : RectangleParticle;
    p1 : RectangleParticle;
    p2 : RectangleParticle;
    p3 : RectangleParticle;
    constructor Create(px, py, w, h: Number; engine: DynamicsEngine);
  end;
  
  DynamicsEngine = class
  public
    gravity    : Vector;
    coeffRest  : Number;
    coeffFric  : Number;
    coeffDamp  : Number;
    
    primitives : TArray;
    surfaces   : TArray;
    constraints: TArray;
    
    constructor Create;
    procedure addPrimitive(p: Particle);
    procedure addSurface(s: Surface);
    procedure addConstraint(c: Constraint);
    procedure paintSurfaces;
    procedure paintPrimitives;
    procedure paintConstraints;
    procedure timeStep;
    procedure setSurfaceBounce(kfr: Number);
    procedure setSurfaceFriction(f: Number);
    procedure setDamping(d: Number);
    procedure setGravity(gx, gy :Number);
  private
    procedure verlet();
    procedure satisfyConstraints();
    procedure checkCollisions();
  end;

implementation

{ Graphics }

procedure paintLine(dmc: MovieClip; x0, y0, x1, y1: Number);
begin
  dmc.moveTo(x0, y0);
  dmc.lineTo(x1, y1);
end;

procedure paintCircle(dmc: MovieClip; x, y, r: Number);
var
  mtp8r: Number;
  msp4r: Number;
begin
  mtp8r := Math.tan(Math.PI/8) * r;
  msp4r := Math.sin(Math.PI/4) * r;
  with dmc do
  begin
    moveTo(x + r, y);
    curveTo(r + x, mtp8r + y, msp4r + x, msp4r + y);
    curveTo(mtp8r + x, r + y, x, r + y);
		curveTo(-mtp8r + x, r + y, -msp4r + x, msp4r + y);
		curveTo(-r + x, mtp8r + y, -r + x, y);
		curveTo(-r + x, -mtp8r + y, -msp4r + x, -msp4r + y);
		curveTo(-mtp8r + x, -r + y, x, -r + y);
		curveTo(mtp8r + x, -r + y, msp4r + x, -msp4r + y);
		curveTo(r + x, -mtp8r + y, r + x, y);
  end;
end;

procedure paintRectangle(dmc: MovieClip; x, y, w, h: Number);
var
  w2: Number;
  h2: Number;
begin
  w2 := w/2;
  h2 := h/2;

  with dmc do
  begin
    moveTo(x - w2, y - h2);
    lineTo(x + w2, y - h2);
    lineTo(x + w2, y + h2);
    lineTo(x - w2, y + h2);
    lineTo(x - w2, y - h2);
  end;
end;

{ Vector }

constructor Vector.Create(px, py: Number);
begin
  x := px;
  y := py;
end;

procedure Vector.setTo(px, py: Number);
begin
  x := px;
  y := py;
end;

procedure Vector.copy(v: Vector);
begin
  x := v.x;
  y := v.y;
end;

function Vector.dot(v: Vector): Number;
begin
	Result := x * v.x + y * v.y;
end;

function Vector.cross(v: Vector): Number;
begin
  Result := x * v.y - y * v.x;
end;

function Vector.plus(v: Vector): Vector;
begin
  x := x + v.x;
  y := y + v.y;
	Result := Self;
end;

function Vector.plusNew(v: Vector): Vector;
begin
  Result := Vector.Create(x + v.x, y + v.y);
end;

function Vector.minus(v: Vector): Vector;
begin
  x := x - v.x;
  y := y - v.y;
  Result := Self;
end;

function Vector.minusNew(v: Vector): Vector;
begin
  Result := Vector.Create(x - v.x, y - v.y);
end;

function Vector.mult(s: Number): Vector;
begin
  x := x * s;
  y := y * s;
  Result := Self;
end;

function Vector.multNew(s: Number): Vector;
begin
  Result := Vector.Create(x * s, y * s);
end;

function Vector.distance(v: Vector): Number;
var
  dx: Number;
  dy: Number;
begin
	dx := x - v.x;
	dy := y - v.y;
	Result := Math.sqrt(dx * dx + dy * dy);
end;

function Vector.normalize(): Vector;
var
  mag: Number;
begin
  mag := Math.sqrt(x * x + y * y);
  x := x / mag;
  y := y / mag;
	Result := Self;
end;

function Vector.magnitude(): Number;
begin
	Result := Math.sqrt(x * x + y * y);
end;

(**
 * projects this vector onto b
 *)
function Vector.project(b: Vector): Vector;
var
  adotb: Number;
  len  : Number;
  proj : Vector;
begin
	adotb := dot(b);
  len := (b.x * b.x + b.y * b.y);

  proj := Vector.Create(0,0);
  proj.x := (adotb / len) * b.x;
  proj.y := (adotb / len) * b.y;
  Result := proj;
end;

{ Line }

constructor Line.Create(p1, p2: Vector);
begin
  Self.p1 := p1;
  Self.p2 := p2;
end;

{ AbstractTile }

constructor AbstractTile.Create(cx, cy: Number);
begin
  center := Vector.Create(cx, cy);
 	verts := TArray.Create();
 	normal := Vector.Create(0,0);

  isVisible := true;
 	isActivated := true;
 	initializeContainer();
end;

procedure AbstractTile.initializeContainer;
var
  depth: Number;
  drawClipName: string;
begin
  depth := _root.getNextHighestDepth();
  drawClipName := "_" + FloatToStr(depth);
  dmc := _root.createEmptyMovieClip(drawClipName, depth);
end;

//TBD:Issues relating to painting, mc's, and visibility could be
//centralized somehow, base class, etc.
procedure AbstractTile.setVisible(v: Boolean);
begin
  isVisible := v;
end;

procedure AbstractTile.setActiveState(a: Boolean);
begin
  isActivated := a;
end;

function AbstractTile.getActiveState: Boolean;
begin
  Result := isActivated;
end;

procedure AbstractTile.createBoundingRect(rw, rh: Number);
var
  t, b, l, r: Number;
begin
	t := center.y - rh/2;
	b := center.y + rh/2;
	l := center.x - rw/2;
	r := center.x + rw/2;

	verts.push(Vector.Create(r,b));
	verts.push(Vector.Create(r,t));
	verts.push(Vector.Create(l,t));
	verts.push(Vector.Create(l,b));
	setCardProjections();
end;

function AbstractTile.testIntervals(boxMin, boxMax, tileMin, tileMax: Number): Number;
var
  depth1: Number;
  depth2: Number;
begin
  // returns 0 if intervals do not overlap. Returns depth if they do overlap
  Result := 0;
  if (boxMax < tileMin) then Exit;
  if (tileMax < boxMin) then Exit;

  // return the smallest translation
  depth1 := tileMax - boxMin;
	depth2 := tileMin - boxMax;

  if (Math.abs(depth1) < Math.abs(depth2)) then
    Result := depth1
  else
    Result := depth2;
end;

procedure AbstractTile.setCardProjections;
begin
  getCardXProjection();
  getCardYProjection();
end;

// get projection onto a cardinal (world) axis x
// TBD: duplicate methods (with different implementation) in
// in the Particle base class.
procedure AbstractTile.getCardXProjection;
var
  i: Integer;
begin
  minX := Vector(verts[0]).x;
  for i := 1 to Integer(verts.length) - 1 do
  begin
    if (Vector(verts[i]).x < minX) then
		  minX := Vector(verts[i]).x;
  end;

  maxX := Vector(verts[0]).x;
  for i := 1 to Integer(verts.length) - 1 do
  begin
  	if (Vector(verts[i]).x > maxX) then
				maxX := Vector(verts[i]).x;
  end;
end;

// get projection onto a cardinal (world) axis y
// TBD: duplicate methods (with different implementation) in
// in the Particle base class.
procedure AbstractTile.getCardYProjection;
var
  i: Integer;
begin
  minY := Vector(verts[0]).y;
  for i := 1 to Integer(verts.length) - 1 do
  begin
    if (Vector(verts[i]).y < minY) then
		  minY := Vector(verts[i]).y;
  end;

  maxY := Vector(verts[0]).y;
  for i := 1 to Integer(verts.length) - 1 do
  begin
  	if (Vector(verts[i]).y > maxY) then
				maxY := Vector(verts[i]).y;
  end;
end;

{ LineSurface }

constructor LineSurface.Create(p1x, p1y, p2x, p2y: Number);
begin
  inherited Create(0,0);
  p1 := Vector.Create(p1x, p1y);
  p2 := Vector.Create(p2x, p2y);

  calcFaceNormal();
  collNormal := Vector.Create(0,0);
  setCollisionDepth(30);
end;

procedure LineSurface.paint;
begin
  if (isVisible) then
  begin
    dmc.clear();
    dmc.lineStyle(0, $222288, 100);
    {Graphics.}paintLine(dmc, p1.x, p1.y, p2.x, p2.y);
  end;
end;

procedure LineSurface.resolveCircleCollision(p: CircleParticle; sysObj:DynamicsEngine);
begin
  if (isCircleColliding(p)) then
  begin
    onContact();
		p.resolveCollision(faceNormal, sysObj);
  end;
end;

procedure LineSurface.resolveRectangleCollision(p: RectangleParticle; sysObj:DynamicsEngine);
begin
  if (isRectangleColliding(p)) then
  begin
	  onContact();
		p.resolveCollision(collNormal, sysObj);
  end;
end;

procedure LineSurface.setCollisionDepth(d: Number);
begin
  collisionDepth := d;
  precalculate();
end;

function LineSurface.isCircleColliding(p: CircleParticle): Boolean;
var
  circleNormal: Vector;
  absCX :Number;
  contactPoint: Vector;
  dx, dy: Number;
begin
  // find the closest point on the surface to the CircleParticle
	findClosestPoint(p.curr, p.closestPoint);

	// get the normal of the circle relative to the location of the closest point
	circleNormal := p.closestPoint.minusNew(p.curr);
	circleNormal.normalize();

	// if the center of the circle has broken the line keep the normal from 'flipping'
	// to the opposite direction. for small circles, this prevents break-throughs
	if (inequality(p.curr)) then
	begin
		absCX := Math.abs(circleNormal.x);
		if (faceNormal.x < 0) then circleNormal.x := absCX else circleNormal.x := -absCX;
		circleNormal.y := Math.abs(circleNormal.y);
  end;

	// get contact point on edge of circle
	contactPoint := p.curr.plusNew(circleNormal.mult(p.radius));
	if (segmentInequality(contactPoint)) then
  begin
		if (contactPoint.distance(p.closestPoint) > collisionDepth) then
		begin
      Result := False;
      Exit;
    end;
		dx := contactPoint.x - p.closestPoint.x;
		dy := contactPoint.y - p.closestPoint.y;
		p.mtd.setTo(-dx, -dy);
		Result := True;
		Exit;
  end;
	Result := False;
end;

function LineSurface.isRectangleColliding(p: RectangleParticle): Boolean;
var
  depthY: Number;
  depthX: Number;
  depthS: Number;
  depthF: Number;
  absX: Number;
  absY: Number;
  absS: Number;
  absF: Number;
begin
  Result := False;
  p.getCardYProjection();
	depthY := testIntervals(p.bmin, p.bmax, minY, maxY);
	if (depthY = 0) then Exit;

	p.getCardXProjection();
	depthX := testIntervals(p.bmin, p.bmax, minX, maxX);
	if (depthX = 0) then Exit;

	p.getAxisProjection(sideNormal);
	depthS := testIntervals(p.bmin, p.bmax, minS, maxS);
	if (depthS = 0) then Exit;

	p.getAxisProjection(faceNormal);
	depthF := testIntervals(p.bmin, p.bmax, minF, maxF);
	if (depthF = 0) then Exit;

	absX := Math.abs(depthX);
	absY := Math.abs(depthY);
	absS := Math.abs(depthS);
	absF := Math.abs(depthF);

	if (absX <= absY) and (absX <= absS) and (absX <= absF) then
	begin
		p.mtd.setTo(depthX, 0);
		collNormal.setTo(p.mtd.x / absX, 0);
	end else
  if (absY <= absX) and (absY <= absS) and (absY <= absF) then
  begin
		p.mtd.setTo(0, depthY);
		collNormal.setTo(0, p.mtd.y / absY);
	end else
  if (absF <= absX) and (absF <= absY) and (absF <= absS) then
  begin
		p.mtd := faceNormal.multNew(depthF);
		collNormal.copy(faceNormal);
	end else
  if (absS <= absX) and (absS <= absY) and (absS <= absF) then
  begin
		p.mtd := sideNormal.multNew(depthS);
		collNormal.copy(sideNormal);
  end;
	Result := True;
end;

procedure LineSurface.precalculate;
begin
  // precalculations for circle collision
  rise := p2.y - p1.y;
  run := p2.x - p1.x;

  // TBD: sign is a quick bug fix, needs to be review
  if run >= 0 then sign := 1 else sign := -1;
  slope := rise / run;
  invB := 1 / (run * run + rise * rise);

  // precalculations for rectangle collision
  createRectangle();
  calcSideNormal();
  setCardProjections();
  setAxisProjections();
end;


procedure LineSurface.calcFaceNormal;
var
  dx, dy: Number;
begin
  faceNormal := Vector.Create(0,0);
  dx := p2.x - p1.x;
	dy := p2.y - p1.y;
  faceNormal.setTo(dy, -dx);
	faceNormal.normalize();
end;

function LineSurface.segmentInequality(toPoint: Vector): Boolean;
var
  u: Number;
  isUnder: Boolean;
begin
  u := findU(toPoint);
  isUnder := inequality(toPoint);
  Result := (u >= 0) and (u <= 1) and (isUnder);
end;

function LineSurface.inequality(toPoint: Vector): Boolean;
var
  line: Number;
begin
 // TBD: sign is a quick bug fix, needs to be review
  line := (slope * (toPoint.x - p1.x) + (p1.y - toPoint.y)) * sign;
	Result := (line <= 0);
end;

procedure LineSurface.findClosestPoint(toPoint, returnVect: Vector);
var
  u, x ,y : Number;
begin
  u := findU(toPoint);
  if (u <= 0) then
  begin
    returnVect.copy(p1);
    Exit;
  end;

  if (u >= 1) then
  begin
	  returnVect.copy(p2);
    Exit;
  end;

  x := p1.x + u * (p2.x - p1.x);
  y := p1.y + u * (p2.y - p1.y);
  returnVect.setTo(x,y);
end;

function LineSurface.findU(p: Vector): Number;
var
  a: Number;
begin
  a := (p.x - p1.x) * run + (p.y - p1.y) * rise;
  Result := a * invB;
end;

procedure LineSurface.createRectangle;
var
  p3x, p3y: Number;
  p4x, p4y: Number;
begin
  p3x := p2.x + -faceNormal.x * collisionDepth;
  p3y := p2.y + -faceNormal.y * collisionDepth;

  p4x := p1.x + -faceNormal.x * collisionDepth;
  p4y := p1.y + -faceNormal.y * collisionDepth;

  p3 := Vector.Create(p3x, p3y);
  p4 := Vector.Create(p4x, p4y);

  verts.push(p1);
  verts.push(p2);
  verts.push(p3);
  verts.push(p4);
end;

procedure LineSurface.setAxisProjections;
var
  temp: Number;
begin
	minF := p2.dot(faceNormal);
	maxF := p3.dot(faceNormal);
	if (minF > maxF) then
	begin
	  temp := minF;
	  minF := maxF;
    maxF := temp;
  end;

  minS := p1.dot(sideNormal);
  maxS := p2.dot(sideNormal);
  if (minS > maxS) then
  begin
	  temp := minS;
		minS := maxS;
		maxS := temp;
  end;
end;

procedure LineSurface.calcSideNormal;
var
  dx, dy: Number;
begin
  sideNormal := Vector.Create(0,0);
  dx := p3.x - p2.x;
  dy := p3.y - p2.y;
  sideNormal.setTo(dy, -dx);
  sideNormal.normalize();
end;

{ RectangleTile }

constructor RectangleTile.Create(cx, cy, rw, rh: Number);
begin
  inherited Create(cx,cy);
  rectWidth := rw;
  rectHeight := rh;
  createBoundingRect(rw, rh);
end;

procedure RectangleTile.paint;
begin
  if(isVisible) then
  begin
		dmc.clear();
		dmc.lineStyle(0, $222288, 100);
		{Graphics.}paintRectangle(dmc, center.x, center.y, rectWidth, rectHeight);
  end;
end;

procedure RectangleTile.resolveCircleCollision(p: CircleParticle; sysObj:DynamicsEngine);
begin
  if (isCircleColliding(p)) then
  begin
		onContact();
		p.resolveCollision(normal, sysObj);
  end;
end;

procedure RectangleTile.resolveRectangleCollision(p: RectangleParticle; sysObj:DynamicsEngine);
begin
  if (isRectangleColliding(p)) then
  begin
	  onContact();
		p.resolveCollision(normal, sysObj);
  end;
end;

function RectangleTile.isCircleColliding(p: CircleParticle): Boolean;
var
  depthX: Number;
  depthY: Number;
  isInVertexX: Boolean;
  isInVertexY: Boolean;
  vx, vy: Number;
  dx, dy: Number;
  mag, pen: Number;
begin
  Result := False;
  
  p.getCardXProjection();
  depthX := testIntervals(p.bmin, p.bmax, minX, maxX);
  if (depthX = 0) then Exit;

  p.getCardYProjection();
  depthY := testIntervals(p.bmin, p.bmax, minY, maxY);
  if (depthY = 0) then Exit;

  // determine if the circle's center is in a vertex voronoi region
  isInVertexX := Math.abs(depthX) < p.radius;
  isInVertexY := Math.abs(depthY) < p.radius;

  if (isInVertexX and isInVertexY) then
  begin

		// get the closest vertex
		vx := center.x + sign(p.curr.x - center.x) * (rectWidth / 2);
		vy := center.y + sign(p.curr.y - center.y) * (rectHeight / 2);

		// get the distance from the vertex to circle center
		dx := p.curr.x - vx;
		dy := p.curr.y - vy;
	  mag := Math.sqrt(dx * dx + dy * dy);
		pen := p.radius - mag;

		// if there is a collision in one of the vertex regions
		if (pen > 0) then
		begin
			dx := dx / mag;
			dy := dy / mag;
			p.mtd.setTo(dx * pen, dy * pen);
			normal.setTo(dx, dy);
			Result := True;
			Exit;
    end;
		Result := False;

	end else begin
		// collision on one of the 4 edges
		p.setXYMTD(depthX, depthY);
		normal.setTo(p.mtd.x / Math.abs(depthX), p.mtd.y / Math.abs(depthY));
		Result := true;
  end;

end;

function RectangleTile.isRectangleColliding(p: RectangleParticle): Boolean;
var
  depthX: Number;
  depthY: Number;
begin
  Result := False;
  p.getCardXProjection();
  depthX := testIntervals(p.bmin, p.bmax, minX, maxX);
  if (depthX = 0) then Exit;

  p.getCardYProjection();
  depthY := testIntervals(p.bmin, p.bmax, minY, maxY);
  if (depthY = 0) then Exit;

  p.setXYMTD(depthX, depthY);
  normal.setTo(p.mtd.x / Math.abs(depthX), p.mtd.y / Math.abs(depthY));
  Result := True;
end;

function RectangleTile.sign(val: Number): Number;
begin
  if val < 0 then Result := -1 else Result := +1;
end;

{ CircleTile }

constructor CircleTile.Create(cx, cy, r: Number);
begin
  inherited Create(cx, cy);
  createBoundingRect(r * 2, r * 2);
  radius := r;
end;

procedure CircleTile.paint;
begin
  if (isVisible) then
  begin
	  dmc.clear();
	  dmc.lineStyle(0, $222288, 100);
		{Graphics.}paintCircle(dmc, center.x, center.y, radius);
  end;
end;

procedure CircleTile.resolveCircleCollision(p: CircleParticle; sysObj:DynamicsEngine);
begin
  if (isCircleColliding(p)) then
  begin
		onContact();
		p.resolveCollision(normal, sysObj);
  end;
end;

procedure CircleTile.resolveRectangleCollision(p: RectangleParticle; sysObj:DynamicsEngine);
begin
  if (isRectangleColliding(p)) then
  begin
    onContact();
		p.resolveCollision(normal, sysObj);
  end;
end;

function CircleTile.isCircleColliding(p: CircleParticle): Boolean;
var
  depthX: Number;
  depthY: Number;
  dx, dy: Number;
  len, pen: Number;
begin
  Result := False;
  p.getCardXProjection();
  depthX := testIntervals(p.bmin, p.bmax, minX, maxX);
  if (depthX = 0) then Exit;

  p.getCardYProjection();
  depthY := testIntervals(p.bmin, p.bmax, minY, maxY);
  if (depthY = 0) then Exit;

  dx := center.x - p.curr.x;
  dy := center.y - p.curr.y;
  len := Math.sqrt(dx * dx + dy * dy);
  pen := (p.radius + radius) - len;

  if (pen > 0) then
  begin
    dx := dx / len;
    dy := dy / len;
    p.mtd.setTo(-dx * pen, -dy * pen);
    normal.setTo(-dx, -dy);
    Result := true;
  end else
    Result := false;
end;

// TBD: This method is basically identical to the isCircleColliding of the
// RectangleTile class. Need some type of CollisionResolver class to handle
// all collisions and move responsibility away from the Surface classes.
function CircleTile.isRectangleColliding(p: RectangleParticle): Boolean;
var
  depthX: Number;
  depthY: Number;
  isInVertexX: Boolean;
  isInVertexY: Boolean;
  vx, vy: Number;
  dx, dy: Number;
  mag, pen: Number;
begin
  Result := False;
  p.getCardXProjection();
  depthX := testIntervals(p.bmin, p.bmax, minX, maxX);
  if (depthX = 0) then Exit;

  p.getCardYProjection();
  depthY := testIntervals(p.bmin, p.bmax, minY, maxY);
  if (depthY = 0) then Exit;

  // determine if the circle's center is in a vertex voronoi region
  isInVertexX := Math.abs(depthX) < radius;
  isInVertexY := Math.abs(depthY) < radius;

  if (isInVertexX and isInVertexY) then
  begin

		// get the closest vertex
		vx := p.curr.x + sign(center.x - p.curr.x) * (p.width / 2);
		vy := p.curr.y + sign(center.y - p.curr.y) * (p.height / 2);
		p.vertex.setTo(vx, vy);

		// get the distance from the vertex to circle center
		dx := p.vertex.x - center.x;
		dy := p.vertex.y - center.y;
		mag := Math.sqrt(dx * dx + dy * dy);
		pen := radius - mag;

		// if there is a collision in one of the vertex regions
		if (pen > 0) then
		begin
			dx := dx / mag;
			dy := dy / mag;
			p.mtd.setTo(dx * pen, dy * pen);
			normal.setTo(dx, dy);
			Result := true;
			Exit;
    end;
		Result := false;

	end else begin
		// collision on one of the 4 edges
		p.setXYMTD(depthX, depthY);
		normal.setTo(p.mtd.x / Math.abs(depthX), p.mtd.y / Math.abs(depthY));
		Result := true;
  end;
end;

// TBD: Put in a util class
function CircleTile.sign(val: Number): Number;
begin
  if val < 0 then Result := -1 else Result := +1;
end;

{ AngularConstraint }

constructor AngularConstraint.Create(p1, p2, p3: Particle);
begin
  pA := p1.curr;
  pB := p2.curr;
  pC := p3.curr;
  
  lineA := Line.Create(pA, pB);
  lineB := Line.Create(pB, pC);
  
  // lineC is the reference line for getting the angle of the line segments
  pD := Vector.Create(pB.x + 0, pB.y - 1);
  lineC := Line.Create(pB, pD);
  
  // theta to constrain to -- domain is -Math.OI to Math.PI
  targetTheta := calcTheta(pA, pB, pC);
  
  // coefficient of stiffness
  stiffness := 1;
end;

procedure AngularConstraint.resolve;
var
  center: Vector;
  abRadius: Number;
  bcRadius: Number;
  thetaABC: Number;
  thetaABD: Number;
  thetaCBD: Number;
  halfTheta: Number;
  paTheta: Number;
  pcTheta: Number;
  newCenter: Vector;
  dfx: Number;
  dfy: Number;
begin
  center := getCentroid;
  
  // make sure the reference line position gets updated
  lineC.p2.x := lineC.p1.x + 0;
  lineC.p2.y := lineC.p1.y - 1;
  
  abRadius := pA.distance(pB);
  bcRadius := pB.distance(pC);
  
  thetaABC := calcTheta(pA, pB, pC);
  thetaABD := calcTheta(pA, pB, pD);
  thetaCBD := calcTheta(pC, pB, pD);
  
  halfTheta := (targetTheta - thetaABC) / 2;
  paTheta := thetaABD + halfTheta * stiffness;
  pcTheta := thetaCBD - halfTheta * stiffness;

	pA.x := abRadius * Math.sin(paTheta) + pB.x;
	pA.y := abRadius * Math.cos(paTheta) + pB.y;
	pC.x := bcRadius * Math.sin(pcTheta) + pB.x;
	pC.y := bcRadius * Math.cos(pcTheta) + pB.y;

	// move corrected angle to pre corrected center
	newCenter := getCentroid();
	dfx := newCenter.x - center.x;
	dfy := newCenter.y - center.y;

	pA.x := pA.X - dfx;
	pA.y := pA.y - dfy;
	pB.x := pB.x - dfx;
	pB.y := pB.y - dfy;
	pC.x := pC.x - dfx;
	pC.y := pC.y - dfy;
end;

procedure AngularConstraint.paint;
begin
  // maintain the constraint interface. angular constraints are
	// painted by their two component SpringConstraints.
end;

procedure AngularConstraint.setStiffness(s: Number);
begin
  stiffness := s;
end;

function AngularConstraint.calcTheta(pa, pb, pc: Vector): Number;
var
  AB: Vector;
  BC: Vector;
  dotProd: Number;
  crossProd: Number;
begin
  AB := Vector.Create(pb.x - pa.x, pb.y - pa.y);
  BC := Vector.Create(pc.x - pb.x, pc.y - pb.y);
  
  dotProd := AB.dot(BC);
  crossProd := AB.cross(BC);
  Result := Math.atan2(crossProd, dotProd);
end;

function AngularConstraint.getCentroid: Vector;
var
  avgX: Number;
  avgY: Number;
begin
  avgX := (pA.x + pB.x + pC.x) / 3;
  avgY := (pA.y + pB.y + pC.y) / 3;
  Result := Vector.Create(avgX, avgY);
end;

{ SpringConstraint }

constructor SpringConstraint.Create(p1, p2: Particle);
begin
  Self.p1 := p1;
	Self.p2 := p2;
	restLength := p1.curr.distance(p2.curr);

	stiffness := 0.5;
	color := $996633;

	initializeContainer();
	isVisible := true;
end;

procedure SpringConstraint.initializeContainer;
var
  depth: Number;
  drawClipName: String;
begin
  depth := _root.getNextHighestDepth();
  drawClipName := "_" + FloatToStr(depth);
  dmc := _root.createEmptyMovieClip(drawClipName, depth);
end;

procedure SpringConstraint.resolve;
var
  delta: Vector;
  deltaLength: Number;
  diff: Number;
  dmd: Vector;
begin
  delta := p1.curr.minusNew(p2.curr);
  deltaLength := p1.curr.distance(p2.curr);

  diff := (deltaLength - restLength) / deltaLength;
  dmd := delta.mult(diff * stiffness);

  p1.curr.minus(dmd);
  p2.curr.plus(dmd);
end;

procedure SpringConstraint.setRestLength(r: Number);
begin
  restLength := r;
end;

procedure SpringConstraint.setStiffness(s: Number);
begin
  stiffness := s;
end;

procedure SpringConstraint.setVisible(v: Boolean);
begin
  isVisible := v;
end;

procedure SpringConstraint.paint;
begin
  if (isVisible) then
  begin
		dmc.clear();
		dmc.lineStyle(0, color, 100);

		{Graphics.}paintLine(
				dmc,
				p1.curr.x,
				p1.curr.y,
				p2.curr.x,
				p2.curr.y);
  end;
end;

{ Particle }

constructor Particle.Create(posX, posY: Number);
begin
  // store initial position, for pinning
  init := Vector.Create(posX, posY);
  
  // current and previous positions - for integration
  curr := Vector.Create(posX, posY);
  prev := Vector.Create(posX, posY);
  temp := Vector.Create(0, 0);
  
  // attributs for collision detection with tiles
  extents := Vector.Create(0, 0);
  
  bmin := 0;
  bmax := 0;
  mtd := Vector.Create(0, 0);
  
  initializeContainer();
  isVisible := True;
end;
	
procedure Particle.initializeContainer();
var
  depth: Number;
  drawClipName: string;
begin
  depth := _root.getNextHighestDepth();
  drawClipName := "_" + FloatToStr(depth);
  dmc := _root.createEmptyMovieClip(drawClipName, depth);
end;

procedure Particle.setVisible(v: Boolean);
begin
  isVisible := v;
end;

procedure Particle.verlet(sysObj: DynamicsEngine);
begin
	temp.x := curr.x;
	temp.y := curr.y;

	curr.x := curr.x + sysObj.coeffDamp * (curr.x - prev.x) + sysObj.gravity.x;
	curr.y := curr.y + sysObj.coeffDamp * (curr.y - prev.y) + sysObj.gravity.y;

	prev.x := temp.x;
	prev.y := temp.y;
end;


procedure Particle.pin();
begin
  curr.x := init.x;
	curr.y := init.y;
	prev.x := init.x;
	prev.y := init.y;
end;


procedure Particle.setPos(px, py:Number);
begin
	curr.x := px;
	curr.y := py;
	prev.x := px;
	prev.y := py;
end;

(**
 * Get projection onto a cardinal (world) axis x
 *)
// TBD: rename to something other than "get"
// TBD: there is another implementation of this in the
// AbstractTile base class.
procedure Particle.getCardXProjection();
begin
	bmin := curr.x - extents.x;
	bmax := curr.x + extents.x;
end;


(**
 * Get projection onto a cardinal (world) axis y
 *)
// TBD: there is another implementation of this in the
// AbstractTile base class. see if they can be combined
procedure Particle.getCardYProjection();
begin
	bmin := curr.y - extents.y;
	bmax := curr.y + extents.y;
end;

(**
 * Get projection onto arbitrary axis. Note that axis need not be unit-length. If
 * it is not, min and max will be scaled by the length of the axis. This is fine
 * if all we're doing is comparing relative values. If we need the 'actual' projection,
 * the axis should be unit length.
 *)
procedure Particle.getAxisProjection(axis: Vector);
var
  absAxis: Vector;
  projectedCenter: Number;
  projectedRadius: Number;
begin
	absAxis := Vector.Create(Math.abs(axis.x), Math.abs(axis.y));
	projectedCenter := curr.dot(axis);
	projectedRadius := extents.dot(absAxis);

  bmin := projectedCenter - projectedRadius;
  bmax := projectedCenter + projectedRadius;
end;

(**
 * Find minimum depth and set mtd appropriately. mtd is the minimum translational
 * distance, the vector along which we must move the box to resolve the collision.
 *)
 //TBD: this is only for right triangle surfaces - make generic
procedure Particle.setMTD(depthX, depthY, depthN:Number; surfNormal:Vector);
var
 absX: Number;
 absY: Number;
 absN: Number;
begin
  absX := Math.abs(depthX);
	absY := Math.abs(depthY);
	absN := Math.abs(depthN);

	if (absX < absY) and (absX < absN) then
		mtd.setTo(depthX, 0)
	else if (absY < absX) and (absY < absN) then
		mtd.setTo(0, depthY)
	else if (absN < absX) and (absN < absY) then
		mtd := surfNormal.multNew(depthN);
end;


(**
 * Set the mtd for situations where there are only the x and y axes to consider.
 *)
procedure Particle.setXYMTD(depthX, depthY: Number);
var
  absX: Number;
  absY: Number;
begin
	absX := Math.abs(depthX);
	absY := Math.abs(depthY);

	if (absX < absY) then
		mtd.setTo(depthX, 0)
	else
		mtd.setTo(0, depthY);
end;

// TBD: too much passing around of the DynamicsEngine object. Probably better if
// it was static.  there is no way to individually set the kfr and friction of the
// surfaces since they are calculated here from properties of the DynamicsEngine
// object. Also, review for too much object creation
procedure Particle.resolveCollision(normal: Vector; sysObj: DynamicsEngine);
var
  vel: Vector;
  sDotV: Number;
  velProjection: Vector;
  perpMomentum: Vector;
  normMomentum: Vector;
  totalMomentum: Vector;
  newVel: Vector;
begin
	// get the velocity
	vel := curr.minusNew(prev);
	sDotV := normal.dot(vel);

	// compute momentum of particle perpendicular to normal
	velProjection := vel.minusNew(normal.multNew(sDotV));
	perpMomentum := velProjection.multNew(sysObj.coeffFric);

	// compute momentum of particle in direction of normal
	normMomentum := normal.multNew(sDotV * sysObj.coeffRest);
	totalMomentum := normMomentum.plusNew(perpMomentum);

	// set new velocity w/ total momentum
	newVel := vel.minusNew(totalMomentum);

	// project out of collision
	curr.plus(mtd);

	// apply new velocity
	prev := curr.minusNew(newVel);
end;

procedure Particle.paint();
begin
end;

procedure Particle.checkCollision(surface: Surface; sysObj: DynamicsEngine);
begin
end;

{ CircleParticle }

constructor CircleParticle.Create(px, py, r: Number);
begin
  inherited Create(px, py);
  radius := r;
  contactRadius := r;
  
  extents := Vector.Create(r, r);
  closestPoint := Vector.Create(0, 0);
end;

procedure CircleParticle.Paint;
begin
  dmc.clear();
  dmc.lineStyle(0, $666666, 100);
  {Graphics.}paintCircle(dmc, curr.x, curr.y, radius);
end;

procedure CircleParticle.checkCollision(surface: Surface; sysObj: DynamicsEngine);
begin
  surface.resolveCircleCollision(Self, sysObj);
end;

{ RimParticle }

constructor RimParticle.Create(r, mt: Number);
begin
  curr := Vector.Create(r, 0);
  prev := Vector.Create(0, 0);

  vs := 0;          // variable speed
  speed := 0;       // initial speed
  maxTorque := mt;
  wr := r;
end;

// TBD: provide a way to get the worldspace position of the rimparticle
// either here, or in the wheel class, so it can be used to move other
// primitives / constraints
procedure RimParticle.verlet(sysObj: DynamicsEngine);
var
  dx: Number;
  dy: Number;
  len: Number;
  ox: Number;
  oy: Number;
  px: Number;
  py: Number;
  clen: Number;
  diff: Number;
begin
	//clamp torques to valid range
	speed := Math.max(-maxTorque, Math.min(maxTorque, speed + vs));

	//apply torque
	//this is the tangent vector at the rim particle
	dx := -curr.y;
	dy :=  curr.x;

	//normalize so we can scale by the rotational speed
	len := Math.sqrt(dx * dx + dy * dy);
	dx := dx / len;
	dy := dy / len;

	curr.x := curr.x + speed * dx;
	curr.y := curr.y + speed * dy;

	ox := prev.x;
	oy := prev.y;
	px := curr.x; prev.x := curr.x;
	py := curr.y; prev.y := curr.y;

	curr.x := curr.x + sysObj.coeffDamp * (px - ox);
	curr.y := curr.y + sysObj.coeffDamp * (py - oy);

	// hold the rim particle in place
	clen := Math.sqrt(curr.x * curr.x + curr.y * curr.y);
	diff := (clen - wr) / clen;

	curr.x := curr.x - curr.x * diff;
	curr.y := curr.y - curr.y * diff;
end;

{ Wheel }

constructor Wheel.Create(x, y, r: Number);
begin
  inherited Create(x, y, r);
	// TBD: set max torque?
	// rim particle (radius, max torque)
	rp := RimParticle.Create(r, 2);

	// TBD:Review this for a higher level of friction
	// 1 = totally slippery, 0 = full friction
	coeffSlip := 0.0;
end;

procedure Wheel.verlet(sysObj: DynamicsEngine);
begin
  rp.verlet(sysObj);
  inherited verlet(sysObj);
end;

procedure Wheel.resolveCollision(normal: Vector; sysObj: DynamicsEngine);
begin
  inherited resolveCollision(normal, sysObj);
  resolve(normal);
end;

procedure Wheel.paint;
var
  px: Number;
  py: Number;
  rx: Number;
  ry: Number;
begin
  if isVisible then
  begin
		// draw wheel circle
		px := curr.x;
		py := curr.y;
		rx := rp.curr.x;
		ry := rp.curr.y;

		dmc.clear();
		dmc.lineStyle(0, $222288, 100);
		{Graphics.}paintCircle(dmc, px, py, radius);

		// draw rim cross
		dmc.lineStyle(0, $999999, 100);
		{Graphics.}paintLine(dmc, rx + px, ry + py, px, py);
		{Graphics.}paintLine(dmc, -rx + px, -ry + py, px, py);
		{Graphics.}paintLine(dmc, -ry + px, rx + py, px, py);
		{Graphics.}paintLine(dmc, ry + px, -rx + py, px, py);
  end;
end;

procedure Wheel.setTraction(t: Number);
begin
  coeffSlip := t;
end;

(**
 * simulates torque/wheel-ground interaction - n is the surface normal
 *)
procedure Wheel.resolve(n: Vector);
var
  rx: Number;
  ry: Number;
  len: Number;
  sx: Number;
  sy: Number;
  tx: Number;
  ty: Number;
  vx: Number;
  vy: Number;
  dp: Number;
  w0: Number;
begin
  // this is the tangent vector at the rim particle
	rx := -rp.curr.y;
	ry := rp.curr.x;

	// normalize so we can scale by the rotational speed
	len := Math.sqrt(rx * rx + ry * ry);
	rx := rx / len;
	ry := ry / len;

	// sx,sy is the velocity of the wheel's surface relative to the wheel
	sx := rx * rp.speed;
	sy := ry * rp.speed;

	// tx,ty is the velocity of the wheel relative to the world
	tx := curr.x - prev.x;
	ty := curr.y - prev.y;

	// vx,vy is the velocity of the wheel's surface relative to the ground
	vx := tx + sx;
	vy := ty + sy;

	// dp is the the wheel's surfacevel projected onto the ground's tangent
	dp := -n.y * vx + n.x * vy;

	// set the wheel's spinspeed to track the ground
	rp.prev.x := rp.curr.x - dp * rx;
	rp.prev.y := rp.curr.y - dp * ry;

	// some of the wheel's torque is removed and converted into linear displacement
	w0 := 1 - coeffSlip;
	curr.x := curr.x + w0 * rp.speed * -n.y;
	curr.y := curr.y + w0 * rp.speed * n.x;
	rp.speed := rp.speed * coeffSlip;
end;

{ RectangleParticle }

constructor RectangleParticle.Create(px, py, w, h: Number);
begin
  inherited Create(px, py);
  width := w;
  height := h;
  
  vertex := Vector.Create(0, 0);
  extents := Vector.Create(w/2, h/2);
end;

procedure RectangleParticle.paint;
begin
  if isVisible then
  begin
    dmc.clear();
    dmc.lineStyle(0, $666666, 100);
    {Graphics.}paintRectangle(dmc, curr.x, curr.y, width, height);
  end;
end;

procedure RectangleParticle.checkCollision(surface: Surface; sysObj: DynamicsEngine);
begin
  surface.resolveRectangleCollision(Self, sysObj);
end;

{ SpringBox }

constructor SpringBox.Create(px, py, w, h: Number; engine: DynamicsEngine);
begin
	// top left
	p0 := RectangleParticle.Create(px - w / 2, py - h / 2, 1, 1);
	// top right
	p1 := RectangleParticle.Create(px + w / 2, py - h / 2, 1, 1);
	// bottom right
	p2 := RectangleParticle.Create(px + w / 2, py + h / 2, 1, 1);
	// bottom left
	p3 := RectangleParticle.Create(px - w / 2, py + h / 2, 1, 1);

	p0.setVisible(false);
	p1.setVisible(false);
	p2.setVisible(false);
	p3.setVisible(false);

	engine.addPrimitive(p0);
	engine.addPrimitive(p1);
	engine.addPrimitive(p2);
	engine.addPrimitive(p3);

	// edges
	engine.addConstraint(SpringConstraint.Create(p0, p1));
	engine.addConstraint(SpringConstraint.Create(p1, p2));
	engine.addConstraint(SpringConstraint.Create(p2, p3));
	engine.addConstraint(SpringConstraint.Create(p3, p0));

	// crossing braces
	engine.addConstraint(SpringConstraint.Create(p0, p2));
	engine.addConstraint(SpringConstraint.Create(p1, p3));
end;

{ DynamicsEngine }

constructor DynamicsEngine.Create;
begin
  primitives := TArray.Create;
  surfaces := TArray.Create;
  constraints := TArray.Create;
  
  // default values
  gravity := Vector.Create(0, 1);
  coeffRest := 1 + 0.5;
  coeffFric := 0.01; // surface friction
  coeffDamp := 0.99; // global damping
end;

procedure DynamicsEngine.addPrimitive(p: Particle);
begin
  primitives.push(p);
end;
  
procedure DynamicsEngine.addSurface(s: Surface);
begin
  surfaces.push(s);
end;

procedure DynamicsEngine.addConstraint(c: Constraint);
begin
  constraints.push(c);
end;

procedure DynamicsEngine.paintSurfaces;
var
  j: Integer;
begin
  for j := 0 to Integer(surfaces.length) - 1 do
    Surface(surfaces[j]).paint();
end;

procedure DynamicsEngine.paintPrimitives;
var
  j: Integer;
begin
  for j := 0 to Integer(primitives.length) - 1 do
    Particle(primitives[j]).paint();
end;

procedure DynamicsEngine.paintConstraints;
var
  j: Integer;
begin
  for j := 0 to Integer(constraints.length) - 1 do
    Constraint(constraints[j]).paint();
end;

procedure DynamicsEngine.timeStep;
begin
  verlet();
  satisfyConstraints();
  checkCollisions();
end;

// TBD: Property of surface, not system
procedure DynamicsEngine.setSurfaceBounce(kfr: Number);
begin
  coeffRest := 1 + kfr;
end;

// TBD: Property of surface, not system
procedure DynamicsEngine.setSurfaceFriction(f: Number);
begin
  coeffFric := f;
end;

procedure DynamicsEngine.setDamping(d: Number);
begin
  coeffDamp := d;
end;

procedure DynamicsEngine.setGravity(gx, gy :Number);
begin
  gravity.x := gx;
  gravity.y := gy;
end;


procedure DynamicsEngine.verlet();
var
  i: Integer;
begin
  for i := 0 to Integer(primitives.length) - 1 do
		Particle(primitives[i]).verlet(Self);
end;

procedure DynamicsEngine.satisfyConstraints();
var
  n: Integer;
begin
  for n := 0 to Integer(constraints.length) - 1 do
		Constraint(constraints[n]).resolve();
end;

procedure DynamicsEngine.checkCollisions();
var
  j: Integer;
  s: Surface;
  i: Integer;
begin
  for j := 0 to Integer(surfaces.length) - 1 do
  begin
	  s := Surface(surfaces[j]);
		if (s.getActiveState()) then
		begin
		  for i := 0 to Integer(primitives.length) - 1 do
				Particle(primitives[i]).checkCollision(s, Self);
    end;
  end;
end;

end.