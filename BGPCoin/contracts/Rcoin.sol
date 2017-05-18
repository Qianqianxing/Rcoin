pragma solidity ^0.4.0;


contract Rcoin{
  address public ICANN=0x7b11dd91c4534dfd28bfa90ab0f26fe4b85fa8b6;
  address public delegatee;
  struct IPB {
    uint32 IP_start;//IP前缀
    uint8 wildnum;//8~24位掩码
    State state;
    address owner;
    address lease;
  }


    struct ASNData
    {
        address owner;
        uint IPBindex;
        uint stime;
        uint validperiod;
    }
    mapping (uint24 => ASNData) public ROA;

    function ASregister(uint24 ASN) returns (bool success)
    {
        if (ROA[ASN].owner != 0) return false;
        if(msg.sender!=ICANN) throw;
        ROA[ASN].owner = ICANN;
        return true;
    }

    function ASallocate(uint24 ASN, address owner) returns (bool success)
    {
        if(msg.sender!=ROA[ASN].owner) throw;
        ROA[ASN].owner = owner;
        ROA[ASN].stime=now;
        ROA[ASN].validperiod=500;
        return true;
    }

    function ASupdate(uint24 ASN, uint IPBindex) returns (bool success)
    {
        if(msg.sender!=ROA[ASN].owner) throw;
        if(msg.sender!=currentIPBs[IPBindex].owner) throw;
        ROA[ASN].IPBindex=IPBindex;
      //  currentIPBs[IPBindex].AS=ASN;
        return true;
    }




  //mapping(address => IPB[]) public Resource;
  enum State { Registered, Delegated, Allocated, Revoked }
  IPB[] public currentIPBs;
  uint32 _IP_start;
  uint index_d;
  int flag;
  event Register(
    uint8 IPstring1,
    uint8 IPstring2,
    uint8 IPstring3,
    uint8 IPstring4,
    uint8 wildnum
    );
  event Delegate(
    uint8 IPstring1,
    uint8 IPstring2,
    uint8 IPstring3,
    uint8 IPstring4,
        uint8 wildnum,
        address delegatee
      );
      event Allocate(
          address owner,
          uint8 IPstring1,
          uint8 IPstring2,
          uint8 IPstring3,
          uint8 IPstring4,
          uint8 wildnum,
          address lease
      );
      event Callback(
              address owner,
              uint8 IPstring1,
              uint8 IPstring2,
              uint8 IPstring3,
              uint8 IPstring4,
              uint8 wildnum,
              address lease
      );
      event Revoke(
        uint8 IPstring1,
        uint8 IPstring2,
        uint8 IPstring3,
        uint8 IPstring4,
              uint8 wildnum,
              address lease
      );

function IPBlock_add(//new Registered的IPB入链
IPB[] _addIPB,uint num, uint bnum//入链位置
) internal
	{
    for(uint j=0;j<num;j++)currentIPBs.push(IPB( _addIPB[j].IP_start,_addIPB[j].wildnum,
			_addIPB[j].state,_addIPB[j].owner,_addIPB[j].lease ));
    for (uint i = currentIPBs.length-1; i>=bnum+num;i--)
    {
      currentIPBs[i].IP_start=currentIPBs[i-num].IP_start;
      currentIPBs[i].wildnum=currentIPBs[i-num].wildnum;
      currentIPBs[i].state=currentIPBs[i-num].state;
      currentIPBs[i].owner=currentIPBs[i-num].owner;
      currentIPBs[i].lease=currentIPBs[i-num].lease;
    }
		for(j=bnum;j<bnum+num;j++)
		{
    currentIPBs[j].IP_start=_addIPB[j-bnum].IP_start;
    currentIPBs[j].wildnum=_addIPB[j-bnum].wildnum;
    currentIPBs[j].state=_addIPB[j-bnum].state;
    currentIPBs[j].owner=_addIPB[j-bnum].owner;
    currentIPBs[j].lease=_addIPB[j-bnum].lease;
		}
  }

	function IPBlock_minut(
uint num, uint bnum
){

  if (bnum+num>currentIPBs.length) throw;
    for (uint i = bnum+num; i<currentIPBs.length;i++)
    {
      currentIPBs[i-num].IP_start=currentIPBs[i].IP_start;
      currentIPBs[i-num].wildnum=currentIPBs[i].wildnum;
      currentIPBs[i-num].state=currentIPBs[i].state;
      currentIPBs[i-num].owner=currentIPBs[i].owner;
      currentIPBs[i-num].lease=currentIPBs[i].lease;
    }
		for(uint j=0;j<num;j++) delete currentIPBs[currentIPBs.length-1];
    currentIPBs.length=currentIPBs.length-num;
  }


//2. 考虑末尾为1的情况
	function IPBlock_next(
uint32 _startIP, uint8 _wildnum
) returns (uint32 )
	{
		_IP_start=_startIP>>(uint (32-_wildnum));
    _IP_start++;//默认此时不会是11111...
    _IP_start=_IP_start<<(uint (32-_wildnum));
      //nextIP=nextIP|_startIP;//默认_startIP是掩码后全为0的合规前缀。
      return _IP_start;
  }


	function IPBlock_Divide(
uint index,
uint32 _startIP, uint8	_wildnum
) returns (uint )
	{
		if(msg.sender!=currentIPBs[index].owner)throw;
		if (currentIPBs[index].wildnum>=_wildnum) throw;

		if (currentIPBs[index].IP_start>_startIP)throw;
		if((currentIPBs[index].IP_start>>(32-currentIPBs[index].wildnum))!=(_startIP>>(32-currentIPBs[index].wildnum)))throw;

		IPB[] memory addIPB=new IPB[](32);//eg. uint[] memory a = new uint[](7);
		uint32 divIP=_startIP;
		uint32 indexIP=currentIPBs[index].IP_start;
		uint8 i=0;
    uint8 newwildnum=0;
		index_d=0;
    uint index_x=_wildnum-currentIPBs[index].wildnum-1;
    int fflag=0;
		while(i<_wildnum-currentIPBs[index].wildnum)
		{
				if((_startIP>>(32-currentIPBs[index].wildnum-i-1))&1==0)
				{
					addIPB[index_x].IP_start=IPBlock_next(indexIP,currentIPBs[index].wildnum+i+1);
					addIPB[index_x].wildnum=currentIPBs[index].wildnum+i+1;
					addIPB[index_x].state=currentIPBs[index].state;
					addIPB[index_x].owner=currentIPBs[index].owner;
					addIPB[index_x].lease=currentIPBs[index].lease;
          index_x--;
				}
				else
				{
          if(fflag!=1){
            fflag=1;
            newwildnum=i+1;
          }
          indexIP=IPBlock_next(indexIP,currentIPBs[index].wildnum+i+1);
					addIPB[index_d].IP_start=indexIP;
					addIPB[index_d].wildnum=currentIPBs[index].wildnum+i+1;
          while(((_startIP>>(32-addIPB[index_d].wildnum-1))&1==0)&&(addIPB[index_d].wildnum<_wildnum))addIPB[index_d].wildnum++;
          if(addIPB[index_d].wildnum<_wildnum)addIPB[index_d].wildnum++;
					addIPB[index_d].state=currentIPBs[index].state;
					addIPB[index_d].owner=currentIPBs[index].owner;
					addIPB[index_d].lease=currentIPBs[index].lease;
          index_d++;
				}
        i++;
		}
		index_d=index_d+index;
    IPBlock_add(addIPB,_wildnum-currentIPBs[index].wildnum,index+1);
    if(fflag==1)currentIPBs[index].wildnum=currentIPBs[index].wildnum+newwildnum;
    else currentIPBs[index].wildnum=currentIPBs[index].wildnum+i;
    return index_d;
	}


/*	function IPBlock_Merge(
IPB[] _seperateIPB
)internal returns (IPB[] MergeIPB)
	{



	}*/
  function IPBlock_leftupdate(uint _updateIPBnum)  returns (bool )
	{
		uint index=_updateIPBnum;
		bool flag1=true;

		if((index>0)
      &&(IPBlock_next(currentIPBs[index-1].IP_start,currentIPBs[index-1].wildnum)==currentIPBs[index].IP_start)
			&&(currentIPBs[index-1].wildnum==currentIPBs[index].wildnum)
			&&(currentIPBs[index-1].owner==currentIPBs[index].owner)
			&&(currentIPBs[index-1].lease==currentIPBs[index].lease)
			){
				currentIPBs[index-1].wildnum=currentIPBs[index].wildnum-1;
				IPBlock_minut(1,index);
				index--;
				flag1=true;
			}
		else flag1=false;
    return flag1;
	}
  function IPBlock_rightupdate(uint _updateIPBnum) returns (bool )
	{
    uint index=_updateIPBnum;
		bool flag2=true;
		if((currentIPBs.length>(index+1))
				&&(IPBlock_next(currentIPBs[index].IP_start,currentIPBs[index].wildnum)==currentIPBs[index+1].IP_start)
				&&(currentIPBs[index].wildnum==currentIPBs[index+1].wildnum)
				&&(currentIPBs[index].owner==currentIPBs[index+1].owner)
				&&(currentIPBs[index].lease==currentIPBs[index+1].lease)
				){
					currentIPBs[index].wildnum=currentIPBs[index].wildnum-1;
					IPBlock_minut(1,index+1);
					flag2=true;
				}
		else flag2=false;
    return flag2;
	}
  function IPBlock_update1(uint _updateIPBnum)  returns (uint )
  {
    uint index=_updateIPBnum;
    bool flag1=IPBlock_leftupdate(index);
    if(flag1==true)
             index=index-1;
    bool flag2=IPBlock_rightupdate(index);
  /*  while((flag1==true)||(flag2==true))
    {
      if((flag1=IPBlock_leftupdate(index))==true)index--;
      flag2=IPBlock_rightupdate(index);
    }*/
    return index;

  }

	function IPBlock_update(uint _updateIPBnum)  returns (uint )
	{
		uint index=_updateIPBnum;
		bool flag1=true;
		bool flag2=true;
		while(flag1||flag2)
		{
		if((index>0)
      &&(IPBlock_next(currentIPBs[index-1].IP_start,currentIPBs[index-1].wildnum)==currentIPBs[index].IP_start)
			&&(currentIPBs[index-1].wildnum==currentIPBs[index].wildnum)
			&&(currentIPBs[index-1].owner==currentIPBs[index].owner)
			&&(currentIPBs[index-1].lease==currentIPBs[index].lease)
			){
				currentIPBs[index-1].wildnum=currentIPBs[index].wildnum-1;
				IPBlock_minut(1,index);
				index--;
				flag1=true;
			}
		else flag1=false;
		if((currentIPBs.length>(index+1))
				&&(IPBlock_next(currentIPBs[index].IP_start,currentIPBs[index].wildnum)==currentIPBs[index+1].IP_start)
				&&(currentIPBs[index].wildnum==currentIPBs[index+1].wildnum)
				&&(currentIPBs[index].owner==currentIPBs[index+1].owner)
				&&(currentIPBs[index].lease==currentIPBs[index+1].lease)
        ){
					currentIPBs[index].wildnum=currentIPBs[index].wildnum-1;
					IPBlock_minut(1,index+1);
					flag2=true;
				}
		else flag2=false;
		}
    index_d=index;
    return index_d;
	}
	function IPBlock_check(uint32 _IP_start,uint8 _wildnum)  returns (int)  {
		for (uint i = 0; i < currentIPBs.length; i++)
		 {
			if (currentIPBs[i].IP_start>_IP_start)
				{
					if (IPBlock_next(currentIPBs[i-1].IP_start,currentIPBs[i-1].wildnum)>
						_IP_start)
						{
              flag=int (i-1);
						return flag;

					}
					else if (IPBlock_next(_IP_start,_wildnum)>currentIPBs[i].IP_start)
							{
                flag=-2;
								return flag;//询问的IP块不在同一个现有块内，说明拥有者不同，操作不合法
							}
							else
							{
                flag=-1;
                return flag;//不在链上
							}
				}
        else if ((currentIPBs[i].IP_start==_IP_start)){
          if(currentIPBs[i].wildnum>_wildnum){
            flag=-1;
            return flag;
          }else
          {
            flag=int (i);
            return flag;
          }
        }
		}
    flag=-1;
		return flag;//不在链上
	}
	function IPBlock_checkExist(uint32 _IP_start,	uint8 _wildnum) returns (int)  {
		for (uint i = 0; i < currentIPBs.length; i++) {
			if (currentIPBs[i].IP_start>_IP_start)
				{
					if (i==0)
					{
						flag=0;
						return flag;
					}
					else if (IPBlock_next(currentIPBs[i-1].IP_start,currentIPBs[i-1].wildnum)>
						_IP_start){
						flag=-1;//已存在，不应入链
						return flag;
					}
					else if (IPBlock_next(_IP_start,_wildnum)>currentIPBs[i].IP_start){
							flag=-1;
							return flag;
						}
					else
					{
						flag=int (i);//入链的位置
						return flag;
					}
				}
        else if ((currentIPBs[i].IP_start==_IP_start)){
          if (currentIPBs[i].wildnum<=_wildnum){
            flag=-1;
            return flag;
          }else
          {
            flag=int (i);//入链的位置
						return flag;
          }
      }
		}
		flag=int (i);
    return flag;
	}

  function covertIP(uint8 IPstring1,uint8 IPstring2,uint8 IPstring3,uint8 IPstring4)  returns (uint32){
    _IP_start=uint32(IPstring1)*256+uint32(IPstring2);
    _IP_start=_IP_start*256+uint32(IPstring3);
    _IP_start=_IP_start*256+uint32(IPstring4);

    //_IP_start=(((uint32(IPstring1)*256+uint32(IPstring2))*256+uint32(IPstring3))*256+uint32(IPstring4);

    return _IP_start;
  }
  function covertfromIP()  returns (uint8 IPstring1,uint8 IPstring2,uint8 IPstring3,uint8 IPstring4){
    IPstring4=uint8 (_IP_start)&uint8(255);
    IPstring3=uint8 (_IP_start>>8)&uint8(255);
    IPstring2=uint8 (_IP_start>>16)&uint8(255);
    IPstring1=uint8 (_IP_start>>24)&uint8(255);
  }
  function registeredIPBnum() returns (uint){
    return currentIPBs.length;
  }

  function readfromIP(uint num)  returns (uint8 IPstring1,uint8 IPstring2,uint8 IPstring3,uint8 IPstring4, uint8 wnum, address user){
    if(currentIPBs.length<(num+1)) throw;
     _IP_start=currentIPBs[num].IP_start;
    IPstring4=uint8 (_IP_start)&uint8(255);
    IPstring3=uint8 (_IP_start>>8)&uint8(255);
    IPstring2=uint8 (_IP_start>>16)&uint8(255);
    IPstring1=uint8 (_IP_start>>24)&uint8(255);
    wnum=currentIPBs[num].wildnum;
    user=currentIPBs[num].lease;
  }

  function register(uint8 IPstring1,uint8 IPstring2,uint8 IPstring3,uint8 IPstring4,	uint8 _wildnum) returns (uint ) {
    if ((_wildnum>24)||(_wildnum<8)) throw;
    _IP_start=covertIP(IPstring1,IPstring2,IPstring3,IPstring4);
    _IP_start=(_IP_start>>(32-_wildnum))<<(32-_wildnum);
    int num=IPBlock_checkExist( _IP_start, _wildnum);
    if (num<0)
     throw;
     uint bnum=uint (num);
    if(msg.sender!=ICANN) throw;
    //IPB[] addIPB;
    //addIPB.push(IPB(_IP_start,_wildnum,State.Registered,ICANN,ICANN));
    IPB[] memory RegisterIPB=new IPB[](1);//eg. uint[] memory a = new uint[](7);
    RegisterIPB[0].IP_start=_IP_start;//IP前缀
    RegisterIPB[0].wildnum=_wildnum;//8~24位掩码
    RegisterIPB[0].state=State.Registered;
    RegisterIPB[0].owner=ICANN;
    RegisterIPB[0].lease=ICANN;
    IPBlock_add(RegisterIPB,1, bnum);
    //IPBlock_update(bnum);
    Register(IPstring1,IPstring2,IPstring3,IPstring4,_wildnum);
    return bnum;
    }

    function delegate(uint8 IPstring1,uint8 IPstring2,uint8 IPstring3,uint8 IPstring4,uint8 _wildnum,address delagatee)  {
          if ((_wildnum>24)||(_wildnum<8)) throw;
          _IP_start=covertIP(IPstring1,IPstring2,IPstring3,IPstring4);
          _IP_start=(_IP_start>>(32-_wildnum))<<(32-_wildnum);

    			int num=IPBlock_check(_IP_start, _wildnum);
    			if (num<0)
    			throw;
    			uint bnum=uint (num);
    			if((msg.sender!=currentIPBs[bnum].owner)||(currentIPBs[bnum].state==State.Allocated))
    			throw;
          if(( _IP_start!=currentIPBs[bnum].IP_start)||(_wildnum!=currentIPBs[bnum].wildnum))
    			bnum=IPBlock_Divide(bnum, _IP_start, _wildnum);
    			currentIPBs[bnum].owner=delagatee;
    			currentIPBs[bnum].lease=delagatee;
    			currentIPBs[bnum].state=State.Delegated;
    			IPBlock_update(bnum);
          Delegate(IPstring1,IPstring2,IPstring3,IPstring4, _wildnum, delagatee);
    		}

    		function allocate(uint8 IPstring1,uint8 IPstring2,uint8 IPstring3,uint8 IPstring4,	uint8 _wildnum,address allocatee)  {
          if ((_wildnum>24)||(_wildnum<8)) throw;
          _IP_start=covertIP(IPstring1,IPstring2,IPstring3,IPstring4);
          _IP_start=(_IP_start>>(32-_wildnum))<<(32-_wildnum);
          int num=IPBlock_check(_IP_start, _wildnum);
    			if (num<0)
    			throw;
    			uint bnum=uint (num);
    			if(msg.sender!=currentIPBs[bnum].owner)
    			throw;
          if(( _IP_start!=currentIPBs[bnum].IP_start)||(_wildnum!=currentIPBs[bnum].wildnum))
    			bnum=IPBlock_Divide(bnum, _IP_start,	_wildnum);
    			currentIPBs[bnum].lease=allocatee;
    			currentIPBs[bnum].state=State.Allocated;
    			IPBlock_update(bnum);
          Allocate(msg.sender,IPstring1,IPstring2,IPstring3,IPstring4,_wildnum,allocatee);
    		}

    		function callback(uint8 IPstring1,uint8 IPstring2,uint8 IPstring3,uint8 IPstring4,	uint8 _wildnum)  {//3、需要两方签名
        if ((_wildnum>24)||(_wildnum<8)) throw;
          _IP_start=covertIP(IPstring1,IPstring2,IPstring3,IPstring4);
          _IP_start=(_IP_start>>(32-_wildnum))<<(32-_wildnum);
          int num=IPBlock_check(_IP_start, _wildnum);
    			if (num<0)
    			throw;
    			uint bnum=uint (num);
    			if(msg.sender!=currentIPBs[bnum].owner)
    			throw;
          if(( _IP_start!=currentIPBs[bnum].IP_start)||(_wildnum!=currentIPBs[bnum].wildnum))
    			bnum=IPBlock_Divide(bnum, _IP_start,	_wildnum);
          Callback(msg.sender,IPstring1,IPstring2,IPstring3,IPstring4, _wildnum,currentIPBs[bnum].lease);
    			currentIPBs[bnum].lease=currentIPBs[bnum].owner;
    			currentIPBs[bnum].state=State.Delegated;
    			IPBlock_update(bnum);

    		}
    		function revoke(uint8 IPstring1,uint8 IPstring2,uint8 IPstring3,uint8 IPstring4,	uint8 _wildnum)  {
          if ((_wildnum>24)||(_wildnum<8)) throw;
          _IP_start=covertIP(IPstring1,IPstring2,IPstring3,IPstring4);
          _IP_start=(_IP_start>>(32-_wildnum))<<(32-_wildnum);
    			int num=IPBlock_check(_IP_start, _wildnum);
    			if (num<0)
    			throw;
    			uint bnum=uint (num);
    			if(msg.sender!=ICANN)
    			throw;
    			currentIPBs[bnum].owner=ICANN;
          Revoke(IPstring1,IPstring2,IPstring3,IPstring4,_wildnum,currentIPBs[bnum].lease);
    			currentIPBs[bnum].lease=ICANN;
    			currentIPBs[bnum].state=State.Revoked;
    			IPBlock_update(bnum);

    		}

}

