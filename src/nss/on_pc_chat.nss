#include "x3_inc_string"
#include "inc_debug"
#include "inc_general"

// -----------------------------------------------------------------------------
// FUNCION AUXILIAR: Colorea texto de rol, susurros y OOC
// -----------------------------------------------------------------------------
string FormatearTextoRol(string sMsg)
{
    string sOut = "";
    int nLen = GetStringLength(sMsg);
    int i;
    string sChar;

    // Estados
    int bEmote   = FALSE;
    int bWhisper = FALSE;
    int bOOC     = FALSE;

    // COLORES
    string sColEmote   = "<c\xDA\x70\xD6>"; // Púrpura
    string sColOOC     = "<c\x22\x8B\x22>"; // Verde
    string sColRed     = "<c\xFF\x60\x60>"; // Rojo Claro (//)
    string sColWhisper = "<c\x90\x90\x90>"; // Gris (*ss*)
    string sReset      = "</c>";

    for(i = 0; i < nLen; i++)
    {
        sChar = GetSubString(sMsg, i, 1);

        // --- 1. DOBLE BARRA // (ROJO) ---
        if (sChar == "/" && GetSubString(sMsg, i, 2) == "//")
        {
            if (bEmote || bOOC || bWhisper) sOut += sReset;
            sOut += sColRed + GetSubString(sMsg, i, nLen - i) + sReset;
            return sOut;
        }

        // --- 2. SUSURRO *ss* (GRIS) ---
        else if (sChar == "*" && GetSubString(sMsg, i, 4) == "*ss*")
        {
            if (!bWhisper)
            {
                if (bOOC || bEmote) sOut += sReset;
                sOut += sColWhisper + "*ss*";
                bWhisper = TRUE;
            }
            else
            {
                sOut += "*ss*" + sReset;
                bWhisper = FALSE;
                if (bEmote) sOut += sColEmote;
                else if (bOOC) sOut += sColOOC;
            }
            i += 3;
        }

        // --- 3. EMOTE NORMAL * (PÚRPURA) ---
        else if (sChar == "*" && !bWhisper)
        {
            if (!bEmote)
            {
                if (bOOC) sOut += sReset + sColEmote + "*";
                else      sOut += sColEmote + "*";
                bEmote = TRUE;
            }
            else
            {
                sOut += "*" + sReset;
                bEmote = FALSE;
                if (bOOC) sOut += sColOOC;
            }
        }

        // --- 4. PARENTESIS ( (VERDE) ---
        else if (sChar == "(" && !bWhisper)
        {
             if (!bOOC)
             {
                 if (bEmote) sOut += sReset + sColOOC + "(";
                 else        sOut += sColOOC + "(";
             }
             else sOut += "(";
             bOOC = TRUE;
        }

        // --- 5. PARENTESIS ) (CERRAR VERDE) ---
        else if (sChar == ")" && !bWhisper)
        {
             sOut += ")" + sReset;
             bOOC = FALSE;
             if (bEmote) sOut += sColEmote;
        }
        else { sOut += sChar; }
    }
    if (bEmote || bOOC || bWhisper) sOut += sReset;
    return sOut;
}
// -----------------------------------------------------------------------------

int CheckDeadSpeak(object oPC)
{
    int bDead = GetIsDead(oPC);
    if (bDead)
    {
        SetPCChatMessage("");
        SendColorMessageToPC(oPC, "Los muertos no pueden hablar.", MESSAGE_COLOR_DANGER);
    }
    return bDead;
}

void DebugBusyNPC(int nTries=0)
{
    WriteTimestampedLogEntry("Reacting to TALKTOME: " + GetName(OBJECT_SELF));
    WriteTimestampedLogEntry("    action = " + IntToString(GetCurrentAction(OBJECT_SELF)));
    WriteTimestampedLogEntry("    in conversation = " + IntToString(IsInConversation(OBJECT_SELF)));

    if (IsInConversation(OBJECT_SELF))
    {
        object oSpeaker = GetPCSpeaker();
        WriteTimestampedLogEntry("    in conversation with = " + GetName(oSpeaker) + " or " + ObjectToString(oSpeaker));
        if (!GetIsObjectValid(oSpeaker) || GetArea(oSpeaker) != GetArea(OBJECT_SELF))
        {
            if (nTries == 0) { ClearAllActions(); SpeakString("¿Eh? Creía que estaba hablando con otra persona."); DelayCommand(1.0, DebugBusyNPC(nTries+1)); return; }
            else if (nTries == 1) { ClearAllActions(); SpeakString("¿Y si doy un pequeño paseo metafórico para despejarme?"); ActionMoveToLocation(GetLocation(OBJECT_SELF)); DelayCommand(1.0, DebugBusyNPC(nTries+1)); return; }
            else if (nTries == 2) {
                ClearAllActions(); SpeakString("¿Quizás debería dejar de ser tímido e intentar iniciar la conversación yo mismo?");
                location lLoc = GetLocation(OBJECT_SELF);
                object oTest = GetFirstObjectInShape(SHAPE_SPHERE, 10.0, lLoc, TRUE);
                while (GetIsObjectValid(oTest)) {
                    if (!GetIsDead(oTest) && GetIsPC(oTest)) { ActionStartConversation(oTest); DelayCommand(1.0, DebugBusyNPC(nTries+1)); return; }
                    oTest = GetNextObjectInShape(SHAPE_SPHERE, 10.0, lLoc, TRUE);
                }
                return;
            }
        }
    }
    if (nTries > 0) SpeakString("Siento lo ocurrido. Ya estoy listo para hablar contigo.");
}

void main()
{
  object oPC = GetPCChatSpeaker();
  if(!GetIsPC(oPC)) return;

  string sVolume;
  int nVol = GetPCChatVolume();

  switch (nVol)
  {
     case TALKVOLUME_TALK:
        if (CheckDeadSpeak(oPC)) return;
        sVolume = "TALK";
        break;
     case TALKVOLUME_WHISPER:
        if (CheckDeadSpeak(oPC)) return;
        sVolume = "WHISPER";
        break;
     case TALKVOLUME_SHOUT: sVolume = "SHOUT"; break;
     case TALKVOLUME_SILENT_SHOUT: sVolume = "SILENT_SHOUT"; break;
     case TALKVOLUME_PARTY: sVolume = "PARTY"; break;
  }

  string sMessage = GetPCChatMessage();
  WriteTimestampedLogEntry(PlayerDetailedName(oPC)+" ["+sVolume+"]: "+sMessage);

  if (GetIsDead(oPC)) return;

  string sLCMessage = GetStringLowerCase(sMessage);
  int nMessageLength = GetStringLength(sLCMessage);

  if(nMessageLength == 0) return;

  // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  // :: COMANDO DM: /ENTORNO (VERSION SOLO CHAT - NO DUPLICADOS)
  // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  if (GetStringLeft(sLCMessage, 9) == "/entorno ")
  {
      if (GetIsDM(oPC))
      {
          string sFlavorText = GetSubString(sMessage, 9, nMessageLength - 9);

          if (sFlavorText != "")
          {
              // Naranja \x01 para evitar corte
              string sOrange = "<c\xFF\x80\x01>";
              string sReset  = "</c>";
              string sFinalEntorno = sOrange + "ENTORNO: " + sFlavorText + sReset;

              // 1. Enviar al propio DM (Solo Chat, para evitar doble log)
              SendMessageToPC(oPC, sFinalEntorno);

              // 2. Enviar a jugadores cercanos
              location lLoc = GetLocation(oPC);
              // bLineOfSight a FALSE para atravesar paredes
              object oTarget = GetFirstObjectInShape(SHAPE_SPHERE, 40.0, lLoc, FALSE, OBJECT_TYPE_CREATURE);

              while (GetIsObjectValid(oTarget))
              {
                  if (GetIsPC(oTarget) && oTarget != oPC)
                  {
                      // Enviamos solo al chat. Esto queda guardado en el historial.
                      // Al quitar el FloatingText, eliminamos la linea repetida.
                      SendMessageToPC(oTarget, sFinalEntorno);
                  }
                  oTarget = GetNextObjectInShape(SHAPE_SPHERE, 40.0, lLoc, FALSE, OBJECT_TYPE_CREATURE);
              }

              SetPCChatMessage("");
              return;
          }
      }
  }

  // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  // :: NOXORIVM
  // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  if (sLCMessage == "noxorivm")
  {
      GiveGoldToCreature(oPC, 10);
      string sYellow = "<c\xFF\xFF\x01>";
      string sReset = "</c>";
      SendMessageToPC(oPC, sYellow + "Debug: Enhorabuena, has mencionado al creador supremo y recibes una modesta ofrenda." + sReset);
      SetPCChatMessage("");
      return;
  }

  // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  // :: SISTEMA DE DADOS (/roll) - ESPAÑOL SOLAMENTE
  // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  if (GetStringLeft(sLCMessage, 5) == "/roll")
  {
        string sType = "";
        int nModifier = 0;

        // --- CARACTERÍSTICAS ---
        if (sLCMessage == "/roll fuerza") {sType = "Fuerza"; nModifier = GetAbilityModifier(ABILITY_STRENGTH, oPC);}
        else if (sLCMessage == "/roll destreza") {sType = "Destreza"; nModifier = GetAbilityModifier(ABILITY_DEXTERITY, oPC);}
        else if (sLCMessage == "/roll constitucion") {sType = "Constitución"; nModifier = GetAbilityModifier(ABILITY_CONSTITUTION, oPC);}
        else if (sLCMessage == "/roll sabiduria") {sType = "Sabiduría"; nModifier = GetAbilityModifier(ABILITY_WISDOM, oPC);}
        else if (sLCMessage == "/roll carisma") {sType = "Carisma"; nModifier = GetAbilityModifier(ABILITY_CHARISMA, oPC);}
        else if (sLCMessage == "/roll inteligencia") {sType = "Inteligencia"; nModifier = GetAbilityModifier(ABILITY_INTELLIGENCE, oPC);}

        // --- SALVACIONES ---
        else if (sLCMessage == "/roll fortaleza") {sType = "Salvación de Fortaleza"; nModifier = GetFortitudeSavingThrow(oPC);}
        else if (sLCMessage == "/roll reflejos") {sType = "Salvación de Reflejos"; nModifier = GetReflexSavingThrow(oPC);}
        else if (sLCMessage == "/roll voluntad") {sType = "Salvación de Voluntad"; nModifier = GetWillSavingThrow(oPC);}

        // --- HABILIDADES ---
        else if (sLCMessage == "/roll empatia animal") {sType = "Empatía Animal"; nModifier = GetSkillRank(SKILL_ANIMAL_EMPATHY, oPC);}
        else if (sLCMessage == "/roll tasacion") {sType = "Tasación"; nModifier = GetSkillRank(SKILL_APPRAISE, oPC);}
        else if (sLCMessage == "/roll concentracion") {sType = "Concentración"; nModifier = GetSkillRank(SKILL_CONCENTRATION, oPC);}
        else if (sLCMessage == "/roll fabricar armaduras") {sType = "Fabricar Armaduras"; nModifier = GetSkillRank(SKILL_CRAFT_ARMOR, oPC);}
        else if (sLCMessage == "/roll fabricar armas") {sType = "Fabricar Armas"; nModifier = GetSkillRank(SKILL_CRAFT_WEAPON, oPC);}
        else if (sLCMessage == "/roll fabricar trampas") {sType = "Fabricar Trampas"; nModifier = GetSkillRank(SKILL_CRAFT_TRAP, oPC);}
        else if (sLCMessage == "/roll inutilizar trampas") {sType = "Inutilizar Trampas"; nModifier = GetSkillRank(SKILL_DISABLE_TRAP, oPC);}
        else if (sLCMessage == "/roll disciplina") {sType = "Disciplina"; nModifier = GetSkillRank(SKILL_DISCIPLINE, oPC);}
        else if (sLCMessage == "/roll sanar") {sType = "Sanar"; nModifier = GetSkillRank(SKILL_HEAL, oPC);}
        else if (sLCMessage == "/roll esconderse") {sType = "Esconderse"; nModifier = GetSkillRank(SKILL_HIDE, oPC);}
        else if (sLCMessage == "/roll intimidar") {sType = "Intimidar"; nModifier = GetSkillRank(SKILL_INTIMIDATE, oPC);}
        else if (sLCMessage == "/roll escuchar") {sType = "Escuchar"; nModifier = GetSkillRank(SKILL_LISTEN, oPC);}
        else if (sLCMessage == "/roll saber popular") {sType = "Saber Popular"; nModifier = GetSkillRank(SKILL_LORE, oPC);}
        else if (sLCMessage == "/roll moverse en silencio") {sType = "Moverse en Silencio"; nModifier = GetSkillRank(SKILL_MOVE_SILENTLY, oPC);}
        else if (sLCMessage == "/roll abrir cerraduras") {sType = "Abrir Cerraduras"; nModifier = GetSkillRank(SKILL_OPEN_LOCK, oPC);}
        else if (sLCMessage == "/roll parada") {sType = "Parada"; nModifier = GetSkillRank(SKILL_PARRY, oPC);}
        else if (sLCMessage == "/roll interpretar") {sType = "Interpretar"; nModifier = GetSkillRank(SKILL_PERFORM, oPC);}
        else if (sLCMessage == "/roll persuadir") {sType = "Persuadir"; nModifier = GetSkillRank(SKILL_PERSUADE, oPC);}
        else if (sLCMessage == "/roll hurtar") {sType = "Hurtar"; nModifier = GetSkillRank(SKILL_PICK_POCKET, oPC);}
        else if (sLCMessage == "/roll montar") {sType = "Montar"; nModifier = GetSkillRank(SKILL_RIDE, oPC);}
        else if (sLCMessage == "/roll buscar") {sType = "Buscar"; nModifier = GetSkillRank(SKILL_SEARCH, oPC);}
        else if (sLCMessage == "/roll avistar") {sType = "Avistar"; nModifier = GetSkillRank(SKILL_SPOT, oPC);}
        else if (sLCMessage == "/roll burlarse") {sType = "Burlarse"; nModifier = GetSkillRank(SKILL_TAUNT, oPC);}
        else if (sLCMessage == "/roll piruetas") {sType = "Piruetas"; nModifier = GetSkillRank(SKILL_TUMBLE, oPC);}
        else if (sLCMessage == "/roll usar objeto magico") {sType = "Usar Objeto Mágico"; nModifier = GetSkillRank(SKILL_USE_MAGIC_DEVICE, oPC);}

        // 1. Tirada
        int nRoll = d20();

        // 2. Cálculo
        int nTotal = nRoll + nModifier;
        string sSigno = (nModifier >= 0) ? " + " : " - ";

        // 3. Resultado visual
        string sCritText = "";
        string sColorRes = "<c\x99\xFF\xFF>";

        if (nRoll == 1) { sCritText = " ¡PIFIA! "; sColorRes = "<c\xFF\x40\x40>"; }
        else if (nRoll == 20) { sCritText = " ¡CRÍTICO! "; sColorRes = "<c\x40\xFF\x40>"; }

        // 4. Construcción del mensaje
        string sNombreTirada = (sType != "") ? "de " + sType : "Genérica";
        string sOOCColor = "<c\x22\x8B\x22>";
        string sReset = "</c>";

        string sFinalMsg = sOOCColor + "(Tirada " + sNombreTirada + ": " + sReset
                         + sColorRes + "1d20[" + IntToString(nRoll) + "]" + sReset
                         + sOOCColor + sSigno + IntToString(abs(nModifier)) + " = " + sReset
                         + sColorRes + IntToString(nTotal) + sCritText + sReset
                         + sOOCColor + ")" + sReset;

        SetPCChatMessage(sFinalMsg);
        return;
  }

  StringReplace(sLCMessage, ".", "");

  if (sLCMessage == "lol" || sLCMessage == "rofl" || sLCMessage == "lmao"|| sLCMessage == "roflmao" || sLCMessage == "haha"|| sLCMessage == "hehe"|| sLCMessage == "hah"|| sLCMessage == "heh"|| sLCMessage == "ha"|| sLCMessage == "lawl")
  {
    PlayVoiceChat(VOICE_CHAT_LAUGH, oPC);
    AssignCommand(oPC, ActionPlayAnimation(ANIMATION_LOOPING_TALK_LAUGHING));
  }

  if (GetStringLeft(sMessage, 10) == "TALK TO ME")
  {
      WriteTimestampedLogEntry(GetName(oPC) + " screamed TALK TO ME.");
      location lLoc = GetLocation(oPC);
      object oTest = GetFirstObjectInShape(SHAPE_SPHERE, 10.0, lLoc, TRUE);
      int nCount = 0;
      while (GetIsObjectValid(oTest))
      {
          if (!GetIsDead(oTest) && !GetIsPC(oTest))
          {
              AssignCommand(oTest, DebugBusyNPC());
              nCount++;
          }
          oTest = GetNextObjectInShape(SHAPE_SPHERE, 10.0, lLoc, TRUE);
      }
      string sFeedback;
      if (nCount == 0) SendMessageToPC(oPC, "No hay reacción inmediata a tu grito.");
      else
      {
        sFeedback = "Tu grito atrae la atención de " + IntToString(nCount) + " " + (nCount > 1 ? "personas cercanas" : "persona cercana") + ".";
        SendMessageToPC(oPC, sFeedback);
      }
      return;
  }

  // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  // :: APLICAR FORMATO DE COLORES DE ROL
  // :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  if (nVol == TALKVOLUME_TALK || nVol == TALKVOLUME_WHISPER)
  {
      string sColoredMsg = FormatearTextoRol(sMessage);
      SetPCChatMessage(sColoredMsg);
  }
}
