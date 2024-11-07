/*
 * Original source from: https://github.com/nimrods8/Atari-2600/blob/master/TIAColorTable.v
 */

/* Atari on an FPGA
Masters of Engineering Project
Cornell University, 2007
Daniel Beer
TIAColorTable.v
Synchronous color lookup table that maps the Atari indexed colors to RGB.
*/

module palette_DB(
  input      [3:0] hue,
  input      [3:0] lum,
  output reg [23:0] rgb_24bpp
);
	always @(*) begin
		case ({hue, lum[3:1]})
		// NTSC Colors
		9'd0:   rgb_24bpp = 24'h000000;
		9'd1:   rgb_24bpp = 24'h404040;
		9'd2:   rgb_24bpp = 24'h6C6C6C;
		9'd3:   rgb_24bpp = 24'h909090;
		9'd4:   rgb_24bpp = 24'hB0B0B0;
		9'd5:   rgb_24bpp = 24'hC8C8C8;
		9'd6:   rgb_24bpp = 24'hDCDCDC;
		9'd7:   rgb_24bpp = 24'hECECEC;
		9'd8:   rgb_24bpp = 24'h444400;
		9'd9:   rgb_24bpp = 24'h646410;
		9'd10:  rgb_24bpp = 24'h848424;
		9'd11:  rgb_24bpp = 24'hA0A034;
		9'd12:  rgb_24bpp = 24'hB8B840;
		9'd13:  rgb_24bpp = 24'hD0D050;
		9'd14:  rgb_24bpp = 24'hE8E85C;
		9'd15:  rgb_24bpp = 24'hFCFC68;
		9'd16:  rgb_24bpp = 24'h702800;
		9'd17:  rgb_24bpp = 24'h844414;
		9'd18:  rgb_24bpp = 24'h985C28;
		9'd19:  rgb_24bpp = 24'hAC783C;
		9'd20:  rgb_24bpp = 24'hBC8C4C;
		9'd21:  rgb_24bpp = 24'hCCA05C;
		9'd22:  rgb_24bpp = 24'hDCB468;
		9'd23:  rgb_24bpp = 24'hECC878;
		9'd24:  rgb_24bpp = 24'h841800;
		9'd25:  rgb_24bpp = 24'h983418;
		9'd26:  rgb_24bpp = 24'hAC5030;
		9'd27:  rgb_24bpp = 24'hC06848;
		9'd28:  rgb_24bpp = 24'hD0805C;
		9'd29:  rgb_24bpp = 24'hE09470;
		9'd30:  rgb_24bpp = 24'hECA880;
		9'd31:  rgb_24bpp = 24'hFCBC94;
		9'd32:  rgb_24bpp = 24'h880000;
		9'd33:  rgb_24bpp = 24'h9C2020;
		9'd34:  rgb_24bpp = 24'hB03C3C;
		9'd35:  rgb_24bpp = 24'hC05858;
		9'd36:  rgb_24bpp = 24'hD07070;
		9'd37:  rgb_24bpp = 24'hE08888;
		9'd38:  rgb_24bpp = 24'hECA0A0;
		9'd39:  rgb_24bpp = 24'hFCB4B4;
		9'd40:  rgb_24bpp = 24'h78005C;
		9'd41:  rgb_24bpp = 24'h8C2074;
		9'd42:  rgb_24bpp = 24'hA03C88;
		9'd43:  rgb_24bpp = 24'hB0589C;
		9'd44:  rgb_24bpp = 24'hC070B0;
		9'd45:  rgb_24bpp = 24'hD084C0;
		9'd46:  rgb_24bpp = 24'hDC9CD0;
		9'd47:  rgb_24bpp = 24'hECB0E0;
		9'd48:  rgb_24bpp = 24'h480078;
		9'd49:  rgb_24bpp = 24'h602090;
		9'd50:  rgb_24bpp = 24'h783CA4;
		9'd51:  rgb_24bpp = 24'h8C58B8;
		9'd52:  rgb_24bpp = 24'hA070CC;
		9'd53:  rgb_24bpp = 24'hB484DC;
		9'd54:  rgb_24bpp = 24'hC49CEC;
		9'd55:  rgb_24bpp = 24'hD4B0FC;
		9'd56:  rgb_24bpp = 24'h140084;
		9'd57:  rgb_24bpp = 24'h302098;
		9'd58:  rgb_24bpp = 24'h4C3CAC;
		9'd59:  rgb_24bpp = 24'h6858C0;
		9'd60:  rgb_24bpp = 24'h7C70D0;
		9'd61:  rgb_24bpp = 24'h9488E0;
		9'd62:  rgb_24bpp = 24'hA8A0EC;
		9'd63:  rgb_24bpp = 24'hBCB4FC;
		9'd64:  rgb_24bpp = 24'h000088;
		9'd65:  rgb_24bpp = 24'h1C209C;
		9'd66:  rgb_24bpp = 24'h3840B0;
		9'd67:  rgb_24bpp = 24'h505CC0;
		9'd68:  rgb_24bpp = 24'h6874D0;
		9'd69:  rgb_24bpp = 24'h7C8CE0;
		9'd70:  rgb_24bpp = 24'h90A4EC;
		9'd71:  rgb_24bpp = 24'hA4B8FC;
		9'd72:  rgb_24bpp = 24'h00187C;
		9'd73:  rgb_24bpp = 24'h1C3890;
		9'd74:  rgb_24bpp = 24'h3854A8;
		9'd75:  rgb_24bpp = 24'h5070BC;
		9'd76:  rgb_24bpp = 24'h6888CC;
		9'd77:  rgb_24bpp = 24'h7C9CDC;
		9'd78:  rgb_24bpp = 24'h90B4EC;
		9'd79:  rgb_24bpp = 24'hA4C8FC;
		9'd80:  rgb_24bpp = 24'h002C5C;
		9'd81:  rgb_24bpp = 24'h1C4C78;
		9'd82:  rgb_24bpp = 24'h386890;
		9'd83:  rgb_24bpp = 24'h5084AC;
		9'd84:  rgb_24bpp = 24'h689CC0;
		9'd85:  rgb_24bpp = 24'h7CB4D4;
		9'd86:  rgb_24bpp = 24'h90CCE8;
		9'd87:  rgb_24bpp = 24'hA4E0FC;
		9'd88:  rgb_24bpp = 24'h003C2C;
		9'd89:  rgb_24bpp = 24'h1C5C48;
		9'd90:  rgb_24bpp = 24'h387C64;
		9'd91:  rgb_24bpp = 24'h509C80;
		9'd92:  rgb_24bpp = 24'h68B494;
		9'd93:  rgb_24bpp = 24'h7CD0AC;
		9'd94:  rgb_24bpp = 24'h90E4C0;
		9'd95:  rgb_24bpp = 24'hA4FCD4;
		9'd96:  rgb_24bpp = 24'h003C00;
		9'd97:  rgb_24bpp = 24'h205C20;
		9'd98:  rgb_24bpp = 24'h407C40;
		9'd99:  rgb_24bpp = 24'h5C9C5C;
		9'd100: rgb_24bpp = 24'h74B474;
		9'd101: rgb_24bpp = 24'h8CD08C;
		9'd102: rgb_24bpp = 24'hA4E4A4;
		9'd103: rgb_24bpp = 24'hB8FCB8;
		9'd104: rgb_24bpp = 24'h143800;
		9'd105: rgb_24bpp = 24'h345C1C;
		9'd106: rgb_24bpp = 24'h507C38;
		9'd107: rgb_24bpp = 24'h6C9850;
		9'd108: rgb_24bpp = 24'h84B468;
		9'd109: rgb_24bpp = 24'h9CCC7C;
		9'd110: rgb_24bpp = 24'hB4E490;
		9'd111: rgb_24bpp = 24'hC8FCA4;
		9'd112: rgb_24bpp = 24'h2C3000;
		9'd113: rgb_24bpp = 24'h4C501C;
		9'd114: rgb_24bpp = 24'h687034;
		9'd115: rgb_24bpp = 24'h848C4C;
		9'd116: rgb_24bpp = 24'h9CA864;
		9'd117: rgb_24bpp = 24'hB4C078;
		9'd118: rgb_24bpp = 24'hCCD488;
		9'd119: rgb_24bpp = 24'hE0EC9C;
		9'd120: rgb_24bpp = 24'h442800;
		9'd121: rgb_24bpp = 24'h644818;
		9'd122: rgb_24bpp = 24'h846830;
		9'd123: rgb_24bpp = 24'hA08444;
		9'd124: rgb_24bpp = 24'hB89C58;
		9'd125: rgb_24bpp = 24'hD0B46C;
		9'd126: rgb_24bpp = 24'hE8CC7C;
		9'd127: rgb_24bpp = 24'hFCE08C;
		endcase
	end
endmodule
