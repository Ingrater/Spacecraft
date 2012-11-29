module game.hud;

import base.renderproxy, base.all, game.player, game.game, game.rules.base;
import core.memory, std.math;
import game.gameobject;
//import renderer.renderproxys: CameraProxy;

class HUD : RenderProxyRenderable!(ObjectInfoText, ObjectInfoRCText, ObjectInfoShape), IRenderable {
private:
	Player m_LocalPlayer;
	GameSimulation m_Game;
	bool m_ShowScore = false;
	bool m_RoundEnd = false;
	bool m_ShowAimingHelp = true;
	
	vec4 m_Color;
  vec2[16] m_VerticesBuf;
	vec2[] m_Vertices;
	vec2 m_Position;
	string m_Text;
  rcstring m_RCText;
	HudTarget m_Target;
	
public:
	this(Player player, GameSimulation game){
		m_LocalPlayer = player;
		m_Game = game;
	}
	
	Player localPlayer(){
		return m_LocalPlayer;
	}
	
	void localPlayer(Player newPlayer){
		m_LocalPlayer = newPlayer;
	}
	
	GameSimulation game(){
		return m_Game;
	}
	
	override IRenderProxy renderProxy(){
		return this;
	}
	
	void showScore(bool visibile){
		m_ShowScore = visibile;
	}
	
	void roundEnd(bool roundEnded){
		m_RoundEnd = roundEnded;
	}
	
	void toggleAimingHelp(){
		m_ShowAimingHelp = !m_ShowAimingHelp;
	}
	
	override void extractImpl(){
		int ww = g_Env.renderer.GetWidth(), wh = g_Env.renderer.GetHeight();
		vec2 center = vec2(ww / 2, wh / 2);
		
		HudTarget target = (localPlayer && localPlayer.firstPerson) ? HudTarget.RENDERTARGET : HudTarget.SCREEN;
		
		if (m_ShowScore || m_RoundEnd){
			auto profile = base.profiler.Profile("scoreboard");
			drawScoreBoard( vec2(50, 50) );
		}
		
		if (localPlayer !is null){
			auto hudprofile = base.profiler.Profile("hud");
			vec2 pos;
			{
				auto profile = base.profiler.Profile("local player");
				if(m_LocalPlayer.firstPerson){
					pos = vec2(ww * 0.1, wh * 0.5); //.y -= wh * 0.4;
				} else {
					pos = vec2(50, wh - 50 - 32);
				}
				drawStatusBar(pos, vec4(0, 1, 0, 0.25), vec4(1, 0, 0, 0.75), vec4(0, 1, 0, 0.75),
					_T("Integrity"), 60, localPlayer.hitpoints / localPlayer.fullHitpoints, target);
				
				pos.y -= 15 + 32;
				drawStatusBar(pos, vec4(0, 0, 1, 0.25), vec4(1, 1, 1, 0.5), vec4(0, 0, 1, 0.5),
					_T("Shield"), 60, localPlayer.shieldStrength / localPlayer.fullShieldStrength, target);
				
				pos.y -= 25 + 32;
				drawStatusBar(pos, vec4(0, 1, 1, 0.25), vec4(0, 0, 1, 0.5), vec4(1, 0, 0, 0.5),
					_T("Temperature"), 80, localPlayer.temperature / localPlayer.fullTemperature, target);
				
				pos.y -= 15 + 32;
				drawStatusBar(pos, vec4(0, 1, 1, 0.25), vec4(0, 0, 1, 0.5), vec4(1, 0, 0, 0.5),
					_T("Booster"), 60, (localPlayer.boostUsage - 1) / (localPlayer.fullBoostUsage - 1), target);
			}
			
			vec2 recutilePos = center;
			if(m_LocalPlayer.firstPerson){
				// Disabled because the offset is obvious when you try to destroy turrets.
				//recutilePos.y -= wh * 0.2;
			}
			else {
				recutilePos.y += wh * 0.05;
			}
			
			if (localPlayer.selected){
				auto profile = base.profiler.Profile("target");
				pos = recutilePos + vec2(50, -15);
				
				vec4 teamColor = teamColorFor(localPlayer.selected.team);
				
				drawRecutile(recutilePos, teamColor, HudTarget.SCREEN);
				auto infoTarget = HudTarget.SCREEN;
				
				// Creative way to draw a text outline... I know, abuse...
				auto outlineColor = vec4(0, 0, 0, 0.25);
				text(outlineColor, pos + vec2(-1, -1), localPlayer.selected.name, infoTarget);
				text(outlineColor, pos + vec2(-1,  1), localPlayer.selected.name, infoTarget);
				text(outlineColor, pos + vec2( 1, -1), localPlayer.selected.name, infoTarget);
				text(outlineColor, pos + vec2( 1,  1), localPlayer.selected.name, infoTarget);
				
				text(outlineColor, pos + vec2( 0, -1), localPlayer.selected.name, infoTarget);
				text(outlineColor, pos + vec2( 1,  0), localPlayer.selected.name, infoTarget);
				text(outlineColor, pos + vec2( 0,  1), localPlayer.selected.name, infoTarget);
				text(outlineColor, pos + vec2(-1,  0), localPlayer.selected.name, infoTarget);
				
				text(teamColor * vec4(0.75, 0.75, 0.75, 2), pos, localPlayer.selected.name, infoTarget);
				
				// Draw the shield and integrity status bars of the target
				pos.y += 17;
				rect(pos + vec2(-1, -1), vec4(1, 1, 1, 0.25), 102, 7, infoTarget);
				statusbar(pos, vec4(0, 0, 1, 0.5), vec4(0, 0, 1, 0.5), 100, 5, localPlayer.selected.shieldStrength / localPlayer.selected.fullShieldStrength, infoTarget);
				pos.y += 10;
				rect(pos + vec2(-1, -1), vec4(1, 1, 1, 0.25), 102, 7, infoTarget);
				statusbar(pos, vec4(1, 0, 0, 0.5), vec4(0, 1, 0, 0.5), 100, 5, localPlayer.selected.hitpoints / localPlayer.selected.fullHitpoints, infoTarget);
				
				// Highlight the target
				if (auto target2 = cast(GameObject) localPlayer.selected){
					auto projection = calculateProjectionMatrix(extractor.origin);
					drawTargetHighlight(localPlayer, target2, teamColor, projection, ww, wh);
				}
			} else {
				auto profile = base.profiler.Profile("recutile");
				drawRecutile(recutilePos, vec4(0, 1, 0, 0.5), HudTarget.SCREEN);
			}
		}
	}
	
	/**
	 * Returns the color for HUD elements of the specified team.
	 */
	private vec4 teamColorFor(byte team){
		vec4 teamColor = vec4(1, 0, 0, 0.5);
		
		// 0 is the free for all team (everyone agains everyone)
		if (team == localPlayer.team && localPlayer.team != 0)
			teamColor = vec4(0, 1, 0, 0.5);
		else if (team < 0)
			teamColor = vec4(0, 1, 1, 0.5);
		
		return teamColor;
	}
	
	private void drawRecutile(vec2 pos, vec4 color, HudTarget target, float scale = 1.0f){
    vec2[4] buf;
    buf[0] = pos + vec2( 10,-25) * scale; buf[1] = pos + vec2( 10,-20) * scale; 
    buf[2] = pos + vec2( 25,-10) * scale; buf[3] = pos + vec2( 20,-10) * scale;
		shape( color, buf, target );

    buf[0] = pos + vec2( 25, 10) * scale; buf[1] = pos + vec2( 20, 10) * scale;
    buf[2] = pos + vec2( 10, 25) * scale; buf[3] = pos + vec2( 10, 20) * scale;
		shape( color, buf, target );

    buf[0] = pos + vec2(-25,-10) * scale; buf[1] = pos + vec2(-20,-10) * scale;
    buf[2] = pos + vec2(-10,-25) * scale; buf[3] = pos + vec2(-10,-20) * scale;
		shape( color, buf, target );

    buf[0] = pos + vec2(-10, 25) * scale; buf[1] = pos + vec2(-10, 20) * scale;
    buf[2] = pos + vec2(-25, 10) * scale; buf[3] = pos + vec2(-20, 10) * scale;
		shape( color, buf, target );
	}
	
	private void drawTargetHighlight(Player player, GameObject target, vec4 teamColor, mat4 projectionMatrix, int winWidth, int winHeight){
		vec3 center3d = vec3(0, 0, 0);
		vec2[8] points2d;
		float depth2d = 0, currentDepth;
		
		foreach(i, vertex; target.boundingBox.vertices){
			center3d = center3d + vertex.toVec3() / points2d.length;
			points2d[i] = transformToScreen(vertex, projectionMatrix, currentDepth);
			depth2d += currentDepth / points2d.length;
		}
		
		auto center2d = transformToScreen(Position(center3d), projectionMatrix, currentDepth);
		
		if (depth2d > 0 && (center2d.x > 0 && center2d.x < winWidth && center2d.y > 0 && center2d.y < winHeight)) {
			// Player sees the center, draw the target markers and aiming position on
			// the screen.
			
			float minX = float.max, minY = float.max, maxX = -float.max, maxY = -float.max;
			foreach(p; points2d){
				if (p.x < minX)
					minX = p.x;
				if (p.x > maxX)
					maxX = p.x;
				
				if (p.y < minY)
					minY = p.y;
				if (p.y > maxY)
					maxY = p.y;
			}
			auto highlightWidth = maxX - minX, highlightHeight = maxY - minY;
			short w = 20, h = 20;
			if (w > highlightWidth / 2)
				w = cast(short)(highlightWidth / 2);
			if (h > highlightHeight / 2)
				h = cast(short)(highlightHeight / 2);
			
			auto boundsColor = teamColor;
			rect(vec2(minX, minY),     boundsColor,  w,      2, HudTarget.SCREEN);
			rect(vec2(minX, minY + 2), boundsColor,  2,    h-2, HudTarget.SCREEN);
			rect(vec2(maxX, minY),     boundsColor, -w,      2, HudTarget.SCREEN);
			rect(vec2(maxX, minY + 2), boundsColor, -2,    h-2, HudTarget.SCREEN);
			rect(vec2(maxX, maxY),     boundsColor, -w,     -2, HudTarget.SCREEN);
			rect(vec2(maxX, maxY - 2), boundsColor, -2, -(h-2), HudTarget.SCREEN);
			rect(vec2(minX, maxY),     boundsColor,  w,     -2, HudTarget.SCREEN);
			rect(vec2(minX, maxY - 2), boundsColor,  2, -(h-2), HudTarget.SCREEN);
			
			if (m_ShowAimingHelp){
				// Calculate the aiming position
				auto distance = (target.position - player.position).length;
				auto timeToImpact = distance / player.weaponVelocity;
				auto aimingPos3d = center3d + target.velocity * timeToImpact;
			
				auto aimingPos2d = transformToScreen(Position(aimingPos3d), projectionMatrix, currentDepth);
				drawTargetMarker(aimingPos2d, vec4(1, 1, 0, 0.5), HudTarget.SCREEN);
			}
		} else {
			// Draw an arrow to hint the player in which direction the target is
			auto screenCenter = vec2((winWidth / 2), winHeight / 2);
			auto dist = center2d - screenCenter;
			auto angle = (depth2d > 0) ? atan2(dist.y, dist.x) : atan2(-dist.y, -dist.x);
			
			void drawArrow(float distFromScreenCenter, vec4 color, vec2[] vertecies){
				// Translate and rotate the vertecies
				auto s = sin(angle), c = cos(angle);
				foreach(ref v; vertecies){
					v.x = v.x + distFromScreenCenter;
					auto x = v.x * c - v.y * s;
					auto y = v.x * s + v.y * c;
					v = vec2(x, y);
				}
				
				shapeAt(screenCenter, color, vertecies, HudTarget.SCREEN);
			}
			
			auto arrowColor = teamColor;
      vec2[6] arrowData;
      arrowData[0] = vec2(0, -10); arrowData[1] = vec2(4, -10); arrowData[2] = vec2(4, 0);
      arrowData[3] = vec2(8, 0); arrowData[4] = vec2(0, 10); arrowData[5] = vec2(4, 10);
			drawArrow(200, arrowColor, arrowData);
      arrowData[0] = vec2(0, -10); arrowData[1] = vec2(4, -10); arrowData[2] = vec2(4, 0);
      arrowData[3] = vec2(8, 0); arrowData[4] = vec2(0, 10); arrowData[5] = vec2(4, 10);
			drawArrow(210, arrowColor, arrowData);
		}
	}
	
	private vec2 transformToScreen(Position worldPos, mat4 projectionMatrix, ref float depth){
		auto winWidth = g_Env.renderer.GetWidth();
		auto winHeight = g_Env.renderer.GetHeight();
		
		auto unitySpacePos = projectionMatrix * vec4(worldPos - extractor.origin);
		unitySpacePos.x = unitySpacePos.x * (1.0f / unitySpacePos.w);
		unitySpacePos.y = unitySpacePos.y * (1.0f / unitySpacePos.w);
		unitySpacePos.z = unitySpacePos.z * (1.0f / unitySpacePos.w);
		if(unitySpacePos.w < 0.0f)
			unitySpacePos.z *= -1.0f;
		depth = unitySpacePos.z;
		
		return vec2(
			(unitySpacePos.x * 0.5 + 0.5) * winWidth,
			winHeight - (unitySpacePos.y * 0.5 + 0.5) * winHeight,
		);
	}
	
	private void drawTargetMarker(vec2 pos, vec4 color, HudTarget target){
    vec2[4] axis;
    axis[0] = vec2(1.0f, 1.0f);
    axis[1] = vec2(-1.0f, 1.0f);
    axis[2] = vec2(-1.0f, -1.0f);
    axis[3] = vec2(1.0f, -1.0f);
		
		foreach(a; axis){
			vec2[4] points;
			points[0] = (vec2(10, 10) + vec2(1, -1)) * a;
			points[1] = (vec2(20, 20) + vec2(1, -1)) * a;
			points[2] = (vec2(10, 10) + vec2(-1, 1)) * a;
			points[3] = (vec2(20, 20) + vec2(-1, 1)) * a;
			shapeAt(pos, color, points, target);
		}
	}
	
	private void drawScoreBoard(vec2 pos){
		ushort ph = 20, bw = 5, ww = 300;
		auto players = game.rules.client.players;
		
		struct TeamStats {
			uint playerCount = 0;
			int kills = 0;
			int deaths = 0;
		}
		
		// Allocate everything on the stack to avoid repeated heap allocations
		TeamStats[129] teams;
		
		// Collect stats from all players
		foreach(player; players){
			// Skip all NPC teams (team < 0) and invalid teams (impossible but just
			// for sure)
			if (player.team >= 0 && player.team < teams.length){
				teams[player.team].playerCount += 1;
				teams[player.team].kills += player.kills();
				teams[player.team].deaths += player.deaths();
			}
		}
		
		// Helper function to draw a score board
		ushort drawTeamScoreBoard(byte team, vec4 color, vec2 pos, rcstring title){
			auto stats = teams[team];
			
			drawWindow(color, pos, title, 60, 12 + 4, ww, cast(uint)(ph * (stats.playerCount + 2.5) + 2*bw), bw, HudTarget.SCREEN);
		
			vec4[2] stripeColors;
      stripeColors[0] = vec4(0.5, 0.5, 0.5, 0.5);
      stripeColors[1] = vec4(0.6, 0.6, 0.6, 0.5);
			ushort top = cast(ushort) (12 + 4 + bw);
			ushort width = cast(ushort) (ww - 2*bw);
			
			// Header
			rect(pos + vec2(bw, top), stripeColors[0], width, ph, HudTarget.SCREEN);
			text(vec4(0.75, 0.75, 0.75, 1), pos + vec2(width - 100, top + 4), _T("Kills"), HudTarget.SCREEN);
			text(vec4(0.75, 0.75, 0.75, 1), pos + vec2(width - 50, top + 4), _T("Deaths"), HudTarget.SCREEN);
			top += ph;
			
			// Team totals
			rect(pos + vec2(bw, top), stripeColors[1], width, ph, HudTarget.SCREEN);
			text(vec4(1, 1, 1, 1), pos + vec2(bw + 4, top + 4), _T("Total"), HudTarget.SCREEN);
			text(vec4(1, 1, 1, 1), pos + vec2(width - 100, top + 4), format("%s", stats.kills), HudTarget.SCREEN);
			text(vec4(1, 1, 1, 1), pos + vec2(width - 50, top + 4), format("%s", stats.deaths), HudTarget.SCREEN);
			top += ph;
			
			// Separator
			rect(pos + vec2(bw, top), stripeColors[0], width, ph / 2, HudTarget.SCREEN);
			top += ph / 2;
			
			uint stripeIndex = 1;
			foreach(clientId, player; players){
				if (player.team == team){
					rect(pos + vec2(bw, top), stripeColors[stripeIndex], width, ph, HudTarget.SCREEN);
					text(vec4(1, 1, 1, 1), pos + vec2(bw + 4, top + 4), player.name, HudTarget.SCREEN);
					text(vec4(1, 1, 1, 1), pos + vec2(width - 100, top + 4), format("%s", player.kills), HudTarget.SCREEN);
					text(vec4(1, 1, 1, 1), pos + vec2(width - 50, top + 4), format("%s", player.deaths), HudTarget.SCREEN);
					
					stripeIndex = (stripeIndex + 1) % stripeColors.length;
					top += ph;
				}
			}
			
			return top;
		}
		
		//foreach(i, t; teams){
		//	base.logger.info("team %s: count %s, kills %s, deaths %s", i, t.playerCount, t.kills, t.deaths);
		//}
		
		// Draw the free for all team if someone is in there
		if (teams[0].playerCount > 0){
			auto usedHeight = drawTeamScoreBoard(0, vec4(0.75, 0.75, 0.75, 0.5), pos, _T("Score"));
			pos.y += usedHeight + bw + 10;
		}
		
		foreach(i, stats; teams[1..$]){
			if (stats.playerCount > 0){
				byte team = cast(byte)(i + 1);
				auto color = teamColorFor(team);
				auto usedHeight = drawTeamScoreBoard(team, color, pos, format("Team %d", team));
				pos.y += usedHeight + bw + 10;
			}
		}
		
		if (m_RoundEnd) {
			text(vec4(1, 0.1, 0.1, 1), pos, _T("Next round will start in a few seconds"), HudTarget.SCREEN);
		} else {
			auto timeLeft = game.rules.client.roundTimeLeft;
			float minutes = floor(timeLeft / 60);
			float seconds = timeLeft % 60;
      string fill = "";
      if(seconds < 10)
        fill = "0";
			text(vec4(1, 1, 1, 1), pos, format("Round ends in %.0f:%s%.0f", minutes, fill, seconds), HudTarget.SCREEN);
		}
	}
	
	
	//
	// High level drawing primitives
	//
	
	private void drawStatusBar(vec2 pos, vec4 windowColor, vec4 emptyColor, vec4 fullColor, rcstring title, uint titleWidth, float percent, HudTarget target){
		drawWindow(windowColor, pos, title, titleWidth, 12 + 4, 150, 16, 2, target);
		statusbar(pos + vec2(3, 19), emptyColor, fullColor, 150 - 4 - 2, 10, percent, target);
	}
	
	private void drawWindow(vec4 color, vec2 pos, rcstring title, uint titleWidth, uint titleHeight, uint winWidth, uint winHeight, uint borderWidth, HudTarget target){
		alias titleHeight th;
		alias titleWidth tw;
		alias winWidth ww;
		alias winHeight wh;
		alias borderWidth bw;
		alias borderWidth bh;
    vec2[4] corners;
		
    corners[0] = vec2(0, 0);
    corners[1] = vec2(0, th);
    corners[2] = vec2(tw, 0);
    corners[3] = vec2(tw + th, th);
		shapeAt(pos, color, corners,target);
		text(vec4(1, 1, 1, 1), pos + vec2(4, 1), title,target);
		
		if (borderWidth > 0){
			auto frame_pos = pos + vec2(0, th);
      corners[0] = vec2(0, 0);
      corners[1] = vec2(0, wh);
      corners[2] = vec2(bw, bh);
      corners[3] = vec2(bw, wh - bh);
			shapeAt(frame_pos, color, corners, target );

      corners[0] = vec2(bw, wh - bh);
      corners[1] = vec2(0, wh);
      corners[2] = vec2(ww - bw, wh - bh);
      corners[3] = vec2(ww, wh);
			shapeAt(frame_pos, color, corners, target );

      corners[0] = vec2(ww - bw, wh - bh);
      corners[1] = vec2(ww, wh);
      corners[2] = vec2(ww - bw, bh);
      corners[3] = vec2(ww, 0);
			shapeAt(frame_pos, color, corners, target );

      corners[0] = vec2(ww - bw, bh);
      corners[1] = vec2(ww, 0);
      corners[2] = vec2(bw, bh);
      corners[3] = vec2(0, 0);
			shapeAt(frame_pos, color, corners, target );
		}
	}
	
	
	//
	// Low level drawing primitives
	//
	
	private void statusbar(vec2 pos, vec4 emptyColor, vec4 fullColor, ushort width, ushort height, float percent, HudTarget target){
		if (percent < 0)
			percent = 0;
		auto color = fullColor * percent + emptyColor * (1 - percent);
		rect(pos, color, cast(ushort)(width * percent), height, target);
	}
	
	private void rect(vec2 pos, vec4 color, int width, int height, HudTarget target){
    vec2[4] corners;
    corners[0] = vec2(0, 0);
    corners[1] = vec2(0, height);
    corners[2] = vec2(width, 0);
    corners[3] = vec2(width, height);
		shapeAt(pos, color, corners, target);
	}
	
	private void shapeAt(vec2 pos, vec4 color, vec2[] vertecies, HudTarget target){
		m_Color = color;
		m_Vertices = m_VerticesBuf[0..vertecies.length];
		foreach(i, vertex; vertecies)
			m_Vertices[i] = vertex + pos;
		m_Target = target;
		produce!ObjectInfoShape();
	}
	
	private void shape(vec4 color, vec2[] vertecies, HudTarget target){
		m_Color = color;
    m_Vertices = m_VerticesBuf[0..vertecies.length];
		m_Vertices[] = vertecies[];
		m_Target = target;
		produce!ObjectInfoShape();
	}
	
	override void initInfo(ref ObjectInfoShape info){
		info.color = m_Color;
		info.vertices = copyArray(m_Vertices);
		info.target = m_Target;
	}
	
	private void text(in vec4 color, in vec2 pos, rcstring content, HudTarget target){
		m_Color = color;
		m_Position = pos;
		m_RCText = content;
		m_Target = target;
		produce!ObjectInfoRCText();
	}

  private void text(in vec4 color, in vec2 pos, string content, HudTarget target)
  {
    assert(extractor.IsInBuffer(content.ptr), "given buffer is not allocated by extractor");
    m_Color = color;
    m_Position = pos;
    m_Text = content;
    m_Target = target;
    produce!ObjectInfoText();
  }
	
	override void initInfo(ref ObjectInfoText info){
		info.pos = m_Position;
		info.text = m_Text;
		info.color = m_Color;
		info.font = 0;
		info.target = m_Target;
	}

  override void initInfo(ref ObjectInfoRCText info)
  {
    info.pos = m_Position;
    info.text = m_RCText;
    info.color = m_Color;
    info.font = 0;
    info.target = m_Target;
  }
	
	
	//
	// Other low level helper stuff
	//
	
	private mat4 calculateProjectionMatrix(Position origin){
		auto cameraProxy = cast(ICameraRenderProxy) game.camera.renderProxy;
		assert(cameraProxy !is null, "hud: the game camera is not a ICameraRenderProxy! Can not get the projection matrix out of it.");
		auto view = cameraProxy.view(origin);
		auto projection = cameraProxy.projection();
		return view * projection;
	}
}
