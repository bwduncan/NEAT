
subroutine abundances(linelist, run, switch_ext,listlength, filename, iteration_result, R)
use mod_abundmaths
use mod_abundtypes
use mod_diagnostics
use mod_getabunds
use mod_abundIO
use mod_helium
use mod_recombination_lines
use mod_extinction
use mod_resultarrays

implicit none

        INTEGER :: count, Iint, fIL, i, j, ion_no1, ion_no2, ion_no3, ion_no4, iii, ion_no5, ion_no6
        INTEGER :: opt, runonce, run
        integer, intent(in) :: listlength
        TYPE(line), dimension(listlength) :: linelist, linelist_orig
        CHARACTER*8 :: lion
        CHARACTER :: switch_ext !switch for extinction laws
        CHARACTER*80 :: filename
        type(resultarray), dimension(1) :: iteration_result

        DOUBLE PRECISION :: normalise, oiiNratio, oiiDens, oiiiTratio, oiiiTemp, oiiiIRNratio, oiiiIRTratio, oiiiIRtemp, oiiiIRdens, niiTratio, niiTemp, ariiiIRNratio, ariiiIRdens, arivNratio, arivDens, cliiiNratio, cliiiDens, siiNratio, siiDens, siiTratio, siiTemp, siiiIRNratio, siiiIRdens, oiiTratio, oiiTemp, neiiiTratio, neiiiIRTratio, neiiiIRNratio, neiiiIRdens, neiiiTemp, neiiiIRTemp, abund, meandensity, meantemp, oitemp, citemp
        DOUBLE PRECISION :: ciiiNratio,neivNratio,nevTratio,siiiTratio,ariiiTratio,arvTratio,lowtemp,lowdens,medtemp,ciiidens,meddens,siiitemp,ariiitemp,hightemp,neivdens,highdens,arvtemp,nevtemp,oiTratio,ciTratio
        DOUBLE PRECISION :: oiiRLabund, niiRLabund, ciiRLabund, cii4267rlabund, neiiRLabund, ciiiRLabund, niiiRLabund, RLabundtemp, weight
        DOUBLE PRECISION :: ciiiCELabund, niiCELabund, niiiIRCELabund, niiiUVCELabund, oiiCELabund, oiiiCELabund, oiiiIRCELabund, oivCELabund, neiiIRCELabund, neiiiIRCELabund, neiiiCELabund, neivCELabund, siiCELabund, siiiCELabund, siiiIRCELabund, sivIRCELabund, cliiiCELabund, ariiiCELabund, arivCELabund, ariiiIRCELabund, nivCELabund, niCELabund, niiiCELabund, ciiCELabund, civCELabund, nvCELabund, nevCELabund, arvCELabund, CELabundtemp, ciCELabund, oiCELabund
        DOUBLE PRECISION :: fn4
        DOUBLE PRECISION :: CELicfO, CELicfC, CELicfN, CELicfNe, CELicfAr, CELicfS, CELicfCl
        DOUBLE PRECISION :: RLicfO, RLicfC, RLicfN, RLicfNe
        DOUBLE PRECISION :: CabundRL, CabundCEL, NabundRL, NabundCEL, OabundRL, OabundCEL, NeabundRL, NeabundCEL, SabundCEL, ArabundCEL, NOabundCEL, NCabundCEL, ClabundCEL
        DOUBLE PRECISION :: adfC, adfN, adfO, adfNe, w1, w2, w3, w4
        DOUBLE PRECISION :: adfC2plus, adfN2plus, adfO2plus, adfNe2plus
        DOUBLE PRECISION :: c1, c2, c3, meanextinction, fl, ratob, tempi, temp, temp2, A4471, A4686, A6678, A5876, R
        REAL :: heiabund,heiiabund,Hetotabund
        REAL*8 :: HW

        DOUBLE PRECISION, DIMENSION(2) :: conditions 
        REAL*8 :: result

        TYPE(line), DIMENSION(:), allocatable :: ILs
        TYPE(line), DIMENSION(38) :: H_BS
        TYPE(line), DIMENSION(4) :: He_lines

! recombination line variables

        TYPE RLabund
           CHARACTER*7 :: Multiplet
           REAL*8 :: Abundance
        END TYPE

        TYPE (RLabund), DIMENSION(12) :: oiimultiplets
        TYPE (RLabund), DIMENSION(7) :: niimultiplets

! strong line variables
        DOUBLE PRECISION :: X23,O_R23upper, O_R23lower, N2,O_N2, O3N2, O_O3N2, Ar3O3, O_Ar3O3, S3O3, O_S3O3, x23temp1, x23temp2, x23temp3, x23temp4

        linelist_orig = linelist
!        linelist = 0
!        ILs%intensity = 0 !not allocated yet
        H_BS%intensity = 0
        He_lines%intensity = 0
        !runonce = 1 !allows printing of supplementary files
        runonce = run !suppresses supplementary files and enables monte-carlo error estimation
!        nivCELabund = 0.0  \
!        nvCELabund = 0.0    |- used to be not calculated, they are now so don't need to be set to zero.
!        civCELabund = 0.0  /

        !file reading stuff

        !reading in Rogers "important" lines list
!$omp critical
        CALL read_ilines(ILs, Iint)
!$omp end critical
!redundant now
!        CALL fileread(linelist, fname1, listlength) ! see above
        CALL element_assign(ILs, linelist, Iint, listlength)

        !dereddening

        ILs%abundance = 0
        ILs%int_dered = 0 
        H_BS%abundance = 0
        H_BS%int_dered = 0 
        He_lines%abundance = 0
        He_lines%int_dered = 0

        !first lets find some hydrogen lines
        CALL get_H(H_BS, linelist, listlength)
        call get_He(He_lines, linelist, listlength)

        !aside: normalisation check, correction

        if(H_BS(2)%intensity .ne. 100)then
                normalise =  DBLE(100) / DBLE(H_BS(2)%intensity)
                do i = 1, Iint !normalising important ions
                        ILs(i)%intensity = ILs(i)%intensity * normalise
                end do
                do i = 1, 4 !normalising balmer series
                        H_BS(i)%intensity = H_BS(i)%intensity*normalise
                end do
                do i = 1,4 !normalise helium
                        He_lines(i)%intensity = He_lines(i)%intensity * normalise
                end do
        endif

        print *, ""
        print *, "Extinction"
        print *, "=========="
        print *, ""

        if (switch_ext == "S") then
                print *,"Using Howarth (1983) galactic law"
        elseif (switch_ext == "H") then
                print *,"Using Howarth (1983) LMC law"
        elseif (switch_ext == "C") then
                print *,"Using CCM (1989) galactic law"
        elseif (switch_ext == "P") then
                print *,"Using Prevot et al. (1984) SMC law"
        elseif (switch_ext == "F") then
                print *,"Using Fitzpatrick (1990) galactic law" 
        endif

        CALL calc_extinction_coeffs(H_BS, c1, c2, c3, meanextinction, switch_ext, R)

        !need to write output/ input stuff so user can insert own c(Hb)
        !assume we go on with calculated extinctions

        print "(1X,A11,F4.2)","Adopted R: ",R

        print "(1X,A17,F5.2)","Ha/Hb => c(Hb) = ",c1
        print "(1X,A17,F5.2)","Hg/Hb => c(Hb) = ",c2
        print "(1X,A17,F5.2)","Hd/Hb => c(Hb) = ",c3

        PRINT "(1X,A13,F4.2,A4,F4.2)", "Mean c(Hb) = ",meanextinction

        if (meanextinction .lt. 0.0) then
           print *,"Derived extinction <0 ; assuming 0"
           meanextinction = 0.0
        endif

        !actual dereddening

        if (switch_ext == "S") then
                CALL deredden(ILs, Iint, meanextinction)
                CALL deredden(H_BS, 4, meanextinction)
                call deredden(He_lines, 4, meanextinction) 
                CALL deredden(linelist, listlength, meanextinction)
        elseif (switch_ext == "H") then
                CALL deredden_LMC(ILs, Iint, meanextinction)
                CALL deredden_LMC(H_BS, 4, meanextinction)
                call deredden_LMC(He_lines, 4, meanextinction) 
                CALL deredden_LMC(linelist, listlength, meanextinction)
        elseif (switch_ext == "C") then
                CALL deredden_CCM(ILs, Iint, meanextinction, R)
                CALL deredden_CCM(H_BS, 4, meanextinction, R)
                call deredden_CCM(He_lines, 4, meanextinction, R) 
                CALL deredden_CCM(linelist, listlength, meanextinction, R)
        elseif (switch_ext == "P") then
                CALL deredden_SMC(ILs, Iint, meanextinction)
                CALL deredden_SMC(H_BS, 4, meanextinction)
                call deredden_SMC(He_lines, 4, meanextinction) 
                CALL deredden_SMC(linelist, listlength, meanextinction)
        elseif (switch_ext == "F") then
                CALL deredden_Fitz(ILs, Iint, meanextinction)
                CALL deredden_Fitz(H_BS, 4, meanextinction)
                call deredden_Fitz(He_lines, 4, meanextinction)
                CALL deredden_Fitz(linelist, listlength, meanextinction)
        endif
 !      print*,'Extinction complete'

!diagnostics
        call get_diag("ciii1909   ","ciii1907   ", ILs, ciiiNratio)        ! ciii ratio
        call get_diag("oii3729    ","oii3726    ", ILs, oiiNratio )        ! oii ratio
        call get_diag("neiv2425   ","neiv2423   ", ILs, neivNratio )       ! neiv ratio
        call get_diag("sii6731    ","sii6716    ", ILs, siiNratio )        ! s ii ratio
        call get_diag("cliii5537  ","cliii5517  ", ILs, cliiiNratio )      ! Cl iii ratio
        call get_diag("ariv4740   ","ariv4711   ", ILs, arivNratio )       ! Ar iv ratio
        call get_diag("oiii88um   ","oiii52um   ", ILs, oiiiIRNratio )     ! oiii ir ratio
        call get_diag("siii33p5um ","siii18p7um ", ILs, siiiIRNratio )       ! siii ir ratio
        call get_diag("neiii15p5um","neiii36p0um", ILs, neiiiIRNratio )       ! neiii ir ratio
        call get_diag("ariii9um   ","ariii21p8um", ILs, ariiiIRNratio )       ! ariii ir ratio

!		print*,'get_diag complete'
! temperature ratios:
        !TODO: try to calculate from atomic data at start
        CALL get_Tdiag("nii6548    ","nii6584    ","nii5754    ", ILs, DBLE(4.054), DBLE(1.3274), niiTratio)        ! N II
        CALL get_Tdiag("oiii5007   ","oiii4959   ","oiii4363   ", ILs, DBLE(1.3356), DBLE(3.98), oiiiTratio)        ! O III
        CALL get_Tdiag("neiii3868  ","neiii3967  ","neiii3342  ", ILs, DBLE(1.3013), DBLE(4.319), neiiiTratio)        ! Ne III
        CALL get_Tdiag("neiii3868  ","neiii3967  ","neiii15p5um", ILs, DBLE(1.3013), DBLE(4.319), neiiiIRTratio)! Ne III ir 
        CALL get_Tdiag("nev3426    ","nev3345    ","nev2975    ", ILs, DBLE(1.3571), DBLE(3.800), nevTratio)        !!ne v
        CALL get_Tdiag("siii9069   ","siii9531   ","siii6312   ", ILs, DBLE(3.47), DBLE(1.403), siiiTratio)        !s iii
        CALL get_Tdiag("ariii7135  ","ariii7751  ","ariii5192  ",ILs, DBLE(1.24), DBLE(5.174), ariiiTratio)        !ar iii
        CALL get_Tdiag("arv6435    ","arv7005    ","arv4625    ",ILs, DBLE(3.125), DBLE(1.471), arvTratio)        !ar v
        CALL get_Tdiag("ci9850     ","ci9824     ","ci8727     ",ILs, DBLE(1.337), DBLE(3.965), ciTratio)      !C I
        CALL get_Tdiag("oi6364     ","oi6300     ","oi5577     ",ILs, DBLE(4.127), DBLE(1.320), oiTratio)      !O I 
        CALL get_Tdiag("oiii4959   ","oiii5007   ","oiii52um   ", ILS, DBLE(1.3356), DBLE(3.98), oiiiIRTratio) ! OIII ir
        !Fixed, DJS

!		print*,'get_Tdiag complete'
! O II


        if(ILs(get_ion("oii7319b    ",ILs, Iint))%int_dered > 0) then

                ion_no1 = get_ion("oii7319b    ",ILs, Iint)
                ion_no2 = get_ion("oii7330b    ",ILs, Iint)
                ion_no3 = get_ion("oii3726    ",ILs, Iint)
                ion_no4 = get_ion("oii3729    ",ILs, Iint)



                if (ion_no1 .gt. 0 .and. ion_no2 .gt. 0 .and. ion_no3 .gt. 0 .and. ion_no4 .gt. 0) then
                        oiiTratio = (ILs(ion_no1)%int_dered+ILs(ion_no2)%int_dered)/(ILs(ion_no3)%int_dered+ILs(ion_no4)%int_dered)
                else
                        oiiTratio = 0.0
                endif

       elseif(ILs(get_ion("oii7319     ",ILs, Iint))%int_dered > 0)then

                ion_no1 = get_ion("oii7319    ",ILs, Iint)
                ion_no2 = get_ion("oii7320    ",ILs, Iint)
                ion_no3 = get_ion("oii7330    ",ILs, Iint)
                ion_no4 = get_ion("oii7331    ",ILs, Iint)
                ion_no5 = get_ion("oii3726    ",ILs, Iint)
                ion_no6 = get_ion("oii3729    ",ILs, Iint)

                if (ion_no1 .gt. 0 .and. ion_no2 .gt. 0 .and. ion_no3 .gt. 0 .and. ion_no4 .gt. 0 .and. ion_no5 .gt. 0 .and. ion_no6 .gt. 0) then
                        oiiTratio = ((ILs(ion_no1)%int_dered+ILs(ion_no2)%int_dered)+(ILs(ion_no3)%int_dered+ILs(ion_no4)%int_dered))/(ILs(ion_no5)%int_dered+ILs(ion_no6)%int_dered)
                else
                        oiiTratio = 0.0
                endif
        !add condition for 3727 blend


       else
                       oiiTratio=0.0 
       endif

! S II
      ion_no1 = get_ion("sii6716    ",ILs, Iint)
      ion_no2 = get_ion("sii6731    ",ILs, Iint)
      ion_no3 = get_ion("sii4068    ",ILs, Iint)
      ion_no4 = get_ion("sii4076    ",ILs, Iint)

      if (ion_no1 .gt. 0 .and. ion_no2 .gt. 0 .and. ion_no3 .gt. 0 .and. ion_no4 .gt. 0) then
           siiTratio = (ILs(ion_no1)%int_dered+ILs(ion_no2)%int_dered)/(ILs(ion_no3)%int_dered+ILs(ion_no4)%int_dered)
      else
           siiTratio = 0.0
      endif

! now get diagnostics zone by zone.

 !     print*,'starting zone diagnostics'

! low ionisation
        ! Edited to stop high limits being included in diagnostic averages. DJS
      lowtemp = 10000.0

      do i = 1,2
        oiiDens=0
        siiDens=0
         count = 0
         if (oiiNratio .gt. 0 .and. oiiNratio .lt. 1e10) then
!		 print*,'get diagnostic oii'
           call get_diagnostic("oii       ","1,2/                ","1,3/                ",oiiNratio,"D",lowtemp, oiiDens)
!		   print*,'diagnostic got'
           count = count + 1
         endif

         if (siiNratio .gt. 0 .and. siiNratio .lt. 1e10) then
!		 print*,'get diagnostic sii'
           call get_diagnostic("sii       ","1,2/                ","1,3/                ",siiNratio,"D",lowtemp, siiDens)
!		   print*,'diagnostic got'
           count = count + 1
         endif

         if (count .eq. 0) then
           lowdens = 1000.0
         else
                lowdens = (oiiDens + siiDens) / count
         endif

         count = 0

         if (oiiTratio .gt. 0 .and. oiiTratio .lt. 1e10) then
           call get_diagnostic("oii       ","2,4,2,5,3,4,3,5/    ","1,2,1,3/            ",oiiTratio,"T",lowdens,oiiTemp)
           count = count + 1

                 if(oiitemp == 20000)then
                        count=count-1
                        oiitemp=-1
                 endif

         else
           oiiTemp = 0.0
         endif

         if (siiTratio .gt. 0 .and. siiTratio .lt. 1e10) then
           call get_diagnostic("sii       ","1,2,1,3/            ","1,4,1,5/            ",siiTratio,"T",lowdens,siiTemp)
           count = count + 1

                if(siitemp == 20000)then
                        count=count-1
                        siitemp=-1
                 endif

         else
           siiTemp = 0.0
         endif

         if (niiTratio .gt. 0 .and. niiTratio .lt. 1e10) then
           call get_diagnostic("nii       ","2,4,3,4/            ","4,5/                ",niiTratio,"T",lowdens,niitemp)
           count = count + 5

                 if(niitemp == 20000)then
                        count=count-5
                        niitemp=-1
                 endif

         else
           niitemp = 0.0
         endif

         if (ciTratio .gt. 0 .and. ciTratio .lt. 1e10) then
           call get_diagnostic("ci        ","2,4,3,4/            ","4,5/                ",ciTratio,"T",lowdens,citemp)
           count = count + 1

                if(citemp == 20000)then
                        count=count-1
                        citemp=-1
                 endif

          else
           citemp = 0.0
         endif

         if (oiTratio .gt. 0 .and. oiTratio .lt. 1e10) then
           call get_diagnostic("oi        ","1,4,2,4/            ","4,5/                ",oiTratio,"T",lowdens,oitemp)
           count = count + 1

         if(oitemp == 20000)then
                 count=count-1
                 oitemp=-1
         endif
         else
           oitemp = 0.0
         endif

         if (count .gt. 0) then
           lowtemp = ((5*niitemp) + siitemp + oiitemp + oitemp + citemp) / count
         else
           lowtemp = 10000.0
         endif

     enddo

! medium ionisation
        cliiiDens = 0
        ciiiDens = 0
        arivDens = 0


      medtemp = 10000.0

      do i = 1,2

         count = 0
         if (cliiiNratio .gt. 0 .and. cliiiNratio .lt. 1e10) then
           call get_diagnostic("cliii     ","1,2/                ","1,3/                ",cliiiNratio,"D",medtemp, cliiiDens)
           count = count + 1
         else
           cliiiDens=0
         endif
         if (ciiiNratio .gt. 0 .and. ciiiNratio .lt. 1e10) then
           call get_diagnostic("ciii      ","1,2/                ","1,3/                ",ciiiNratio,"D",medtemp, ciiiDens)
           count = count + 1
         else
           ciiiDens=0
         endif
         if (arivNratio .gt. 0 .and. arivNratio .lt. 1e10) then
           call get_diagnostic("ariv      ","1,2/                ","1,3/                ",arivNratio,"D",medtemp, arivDens)
           count = count + 1
         else
           arivDens=0
         endif

! IR densities, not included in average
!Ar, S, Ne, O

         if (oiiiIRNratio .gt. 0 .and. oiiiIRNratio .lt. 1e10) then
           call get_diagnostic("oiii      ","1,2/                ","2,3/                ",oiiiIRNratio,"D",medtemp, oiiiIRDens)
         endif

         if (ariiiIRNratio .gt. 0 .and. ariiiIRNratio .lt. 1e10) then
           call get_diagnostic("ariii     ","1,2/                ","2,3/                ",ariiiIRNratio,"D",medtemp, ariiiIRDens)
         endif

         if (siiiIRNratio .gt. 0 .and. siiiIRNratio .lt. 1e10) then
           call get_diagnostic("siii      ","1,2/                ","2,3/                ",siiiIRNratio,"D",medtemp, siiiIRDens)
         endif

         if (neiiiIRNratio .gt. 0 .and. neiiiIRNratio .lt. 1e10) then
           call get_diagnostic("neiii     ","1,2/                ","2,3/                ",neiiiIRNratio,"D",medtemp, neiiiIRDens)
         endif

         if (count .eq. 0) then
           meddens = 1000.0
         else
           meddens = (ciiiDens + cliiiDens + arivDens) / count
         endif

         count = 0

         if (oiiiTratio .gt. 0 .and. oiiiTratio .lt. 1e10) then
           call get_diagnostic("oiii      ","2,4,3,4/            ","4,5/                ",oiiiTratio,"T",meddens,oiiiTemp)
           count = count + 4
                 if(oiiitemp == 20000)then
                         count=count-4
                         oiiitemp=-1
                 endif
         else
           oiiiTemp = 0.0
         endif

         if (siiiTratio .gt. 0 .and. siiiTratio .lt. 1e10) then
           call get_diagnostic("siii      ","2,4,3,4/            ","4,5/                ",siiiTratio,"T",meddens,siiiTemp)
           count = count + 1

                if(siiitemp == 20000)then
                         count=count-1
                         siiitemp=-1
                 endif

         else
           siiiTemp = 0.0
         endif

         if (ariiiTratio .gt. 0 .and. ariiiTratio .lt. 1e10) then
           call get_diagnostic("ariii     ","1,4,2,4/            ","4,5/                ",ariiiTratio,"T",meddens,ariiitemp)
           count = count + 2
                 if(ariiitemp == 20000)then
                         count=count-2
                         ariiitemp=-1
                 endif
         else
           ariiitemp = 0.0
         endif

         if (neiiiTratio .gt. 0 .and. neiiiTratio .lt. 1e10) then
           call get_diagnostic("neiii     ","1,4,2,4/            ","4,5/                ",neiiiTratio,"T",meddens,neiiitemp)
           count = count + 2
                if(neiiitemp == 20000)then
                         count=count-2
                         neiiitemp=-1
                 endif

         else
           neiiitemp = 0.0
         endif

!extra IR temperatures, not included in the average at the moment but could be if we decide that would be good

         if (neiiiIRTratio .gt. 0 .and. neiiiIRTratio .lt. 1.e10) then
           call get_diagnostic("neiii     ","1,4,2,4/            ","1,2/                ",neiiiIRTratio,"T",meddens,neiiiIRtemp)
         else
           neiiiIRtemp = 0.0
         endif

         if (oiiiIRTratio .gt. 0 .and. oiiiIRTratio .lt. 1.e10) then
           call get_diagnostic("oiii      ","2,4,3,4/            ","2,3/                ",oiiiIRTratio,"T",oiiiIRdens,oiiiIRtemp)
         else
           oiiiIRtemp = 0.0
         endif


!averaging

         if (count .gt. 0) then
           medtemp = (4*oiiitemp + siiitemp + 2*ariiitemp + 2*neiiitemp) / count
         else
           medtemp = 10000.0
         endif

        !dereddening again 



        ILs%int_dered = 0 
        H_BS%int_dered = 0 
        He_lines%int_dered = 0

        !aside: normalisation check, correction

        !update extinction. DS 22/10/11
        meanextinction=0        
        CALL calc_extinction_coeffs_loop(H_BS, c1, c2, c3, meanextinction, switch_ext, medtemp, lowdens, R)
        print*, "iteration", i, " extinction:"
        print "(1X,A17,F4.2,A4,F4.2)","Ha/Hb => c(Hb) = ",c1
        print "(1X,A17,F4.2,A4,F4.2)","Hg/Hb => c(Hb) = ",c2
        print "(1X,A17,F4.2,A4,F4.2)","Hd/Hb => c(Hb) = ",c3

        PRINT "(1X,A13,F4.2,A4,F4.2)", "Mean c(Hb) = ",meanextinction

        if (meanextinction .lt. 0.0) then
           print *,"Derived extinction <0 ; assuming 0"
           meanextinction = 0.0
        endif

        linelist = linelist_orig
        if (switch_ext == "S") then
                CALL deredden(ILs, Iint, meanextinction)
                CALL deredden(H_BS, 4, meanextinction)
                call deredden(He_lines, 4, meanextinction) 
                CALL deredden(linelist, listlength, meanextinction)
        elseif (switch_ext == "H") then
                CALL deredden_LMC(ILs, Iint, meanextinction)
                CALL deredden_LMC(H_BS, 4, meanextinction)
                call deredden_LMC(He_lines, 4, meanextinction) 
                CALL deredden_LMC(linelist, listlength, meanextinction)
        elseif (switch_ext == "C") then
                CALL deredden_CCM(ILs, Iint, meanextinction, R)
                CALL deredden_CCM(H_BS, 4, meanextinction, R)
                call deredden_CCM(He_lines, 4, meanextinction, R) 
                CALL deredden_CCM(linelist, listlength, meanextinction, R)
        elseif (switch_ext == "P") then
                CALL deredden_SMC(ILs, Iint, meanextinction)
                CALL deredden_SMC(H_BS, 4, meanextinction)
                call deredden_SMC(He_lines, 4, meanextinction) 
                CALL deredden_SMC(linelist, listlength, meanextinction)
        elseif (switch_ext == "F") then
                CALL deredden_Fitz(ILs, Iint, meanextinction)
                CALL deredden_Fitz(H_BS, 4, meanextinction)
                call deredden_Fitz(He_lines, 4, meanextinction)
                CALL deredden_Fitz(linelist, listlength, meanextinction)
        endif

      enddo

        if (runonce == 0 .and. meanextinction > 0) iteration_result(1)%mean_cHb = meanextinction


! high ionisation
      hightemp = medtemp

      do i = 1,2

         if (neivNratio .gt. 0 .and. neivNratio .lt. 1e10) then
           call get_diagnostic("neiv      ","1,2/                ","1,3/                ",neivNratio,"D",hightemp, neivDens)
           highdens = neivdens
         else
           neivDens = 0.0
           highdens = meddens
         endif

         count = 0

         if (arvTratio .gt. 0 .and. arvTratio .lt. 1e10) then
           call get_diagnostic("arv       ","2,4,3,4/            ","4,5/                ",arvTratio,"T",highdens,arvTemp)
           count = count + 1
         else
           arvTemp = 0.0
         endif

         if (nevTratio .gt. 0 .and. nevTratio .lt. 1e10) then
           call get_diagnostic("nev       ","2,4,3,4/            ","4,5/                ",nevTratio,"T",highdens,nevtemp)
           count = count + 1
         else
           nevtemp = 0.0
         endif

         if (count .gt. 0) then
           hightemp = (arvtemp + nevtemp) / count
         else
           hightemp = medtemp
         endif

      enddo
!done calculating, now write out.


!edited diagnostic section to reflect above changes which stopped high/low limit densities/temperatures being included in averages. High limit cases set to 0.1 so that we know that it was in the high limit and not the low limit. DJS


      print *,""
      print *,"Diagnostics"
      print *,"==========="
      print *,""

      print *,"Diagnostic       Zone      Value    Diagnostic ratio"
      print *,""
if(oiidens >0)     print "(A28,F8.0,A1,F8.3)","[O II] density   Low       ",oiidens, " ", oiiNratio
        if(runonce == 0 .and. oiidens > 0) iteration_result(1)%OII_density = oiidens
if(siidens >0)     print "(A28,F8.0,A1,F8.3)","[S II] density   Low       ",siidens, " ", REAL(1/siiNratio)
        if(runonce == 0 .and. siidens > 0) iteration_result(1)%SII_density = siidens
if(lowdens >0)     print "(A28,F8.0)"," density adopted Low       ",lowdens
        if(runonce == 0 .and. lowdens > 0) iteration_result(1)%low_density = lowdens
if(lowdens >0)     print *,""



if(niitemp > 0.2)then
                   print "(A28,F8.0,A1,F8.3)","[N II] temp      Low       ",niitemp, " ", niitratio
        if(runonce == 0) iteration_result(1)%OII_temp = niitemp
else if(INT(niitemp) == -1)then
                   print "(A28,F8.0,A1,F8.3)","[N II] temp      Low       ",20000.0, " ", niitratio
        if(runonce == 0) iteration_result(1)%OII_temp = 20000
else

endif

if(oiitemp >0.2)then
                   print "(A28,F8.0,A1,F8.3)","[O II] temp      Low       ",oiitemp, " ", REAL(1/oiitratio)
        if(runonce == 0) iteration_result(1)%NII_temp = oiitemp
else if(INT(oiitemp) == -1)then
                   print "(A28,F8.0,A1,F8.3)","[O II] temp      Low       ",20000.0, " ", REAL(1/oiitratio)
        if(runonce == 0) iteration_result(1)%NII_temp = 20000
else
endif

if(siitemp >0.2 )then
                   print "(A28,F8.0,A1,F8.3)","[S II] temp      Low       ",siitemp, " ", siitratio
        if(runonce == 0) iteration_result(1)%SII_temp = siitemp
else if(INT(siitemp) == -1)then
                   print "(A28,F8.0,A1,F8.3)","[S II] temp      Low       ",20000.0, " ", siitratio
        if(runonce == 0) iteration_result(1)%SII_temp = 20000
else
endif

if(oitemp >0.2 )then
                   print "(A28,F8.0,A1,F8.3)","[O I]  temp      Low       ",oitemp, " ", oitratio
        if(runonce == 0) iteration_result(1)%OI_temp = oitemp
else if(INT(oitemp) == -1)then
                   print "(A28,F8.0,A1,F8.3)","[O I]  temp      Low       ",20000.0, " ", oitratio
        if(runonce == 0) iteration_result(1)%OI_temp = 20000
else
endif

if(citemp >0.2 )then
                   print "(A28,F8.0,A1,F8.3)","[C I]  temp      Low       ",citemp, " ", citratio
        if(runonce == 0) iteration_result(1)%CI_temp = citemp
else if(INT(citemp) == -1)then
                   print "(A28,F8.0,A1,F8.3)","[C I]  temp      Low       ",20000.0, " ", citratio
        if(runonce == 0) iteration_result(1)%CI_temp = 20000
else
endif


if(lowtemp >0)     print "(A28,F8.0)"," temp adopted    Low       ",lowtemp
        if(runonce == 0 .and. lowtemp > 0) iteration_result(1)%low_temp = lowtemp
if(lowtemp >0)     print *,""

if(cliiidens > 0 )    print "(A28,F8.0,A1,F8.3)","[Cl III] density Medium    ",cliiidens," ", cliiinratio
        if(runonce == 0 .and. cliiidens > 0 ) iteration_result(1)%ClIII_density = cliiidens
if(arivdens  > 0 )    print "(A28,F8.0,A1,F8.3)","[Ar IV] density  Medium    ",arivdens," ", arivnratio
        if(runonce == 0 .and. arivdens > 0 ) iteration_result(1)%ArIV_density = arivdens
if(ciiidens  > 0 )    print "(A28,F8.0,A1,F8.3)","C III] density   Medium    ",ciiidens," ", ciiinratio
        if(runonce == 0 .and. ciiidens > 0 ) iteration_result(1)%CIII_density = ciiidens
if(oiiiIRdens  > 0 )    print "(A28,F8.0,A1,F8.3)","[O III] IR dens Medium     ",oiiiIRdens," ", oiiiIRnratio
        if(runonce == 0 .and. oiiiIRdens > 0 ) iteration_result(1)%OIII_IR_density = oiiiIRdens
if(ariiiIRdens  > 0 )    print "(A28,F8.0,A1,F8.3)","[Ar III] IR dens Medium    ",ariiiIRdens," ", ariiiIRnratio
        if(runonce == 0 .and. ariiiIRdens > 0 ) iteration_result(1)%ArIII_IR_density = ariiiIRdens
if(siiiIRdens  > 0 )    print "(A28,F8.0,A1,F8.3)","[S III] IR dens Medium     ",siiiIRdens," ", siiiIRnratio
        if(runonce == 0 .and. siiiIRdens > 0 ) iteration_result(1)%SIII_IR_density = siiiIRdens
if(neiiiIRdens  > 0 )    print "(A28,F8.0,A1,F8.3)","[Ne III] IR dens Medium    ",neiiiIRdens," ", neiiiIRnratio
        if(runonce == 0 .and. neiiiIRdens > 0 ) iteration_result(1)%NeIII_IR_density = neiiiIRdens

if(meddens   > 0 )    print "(A28,F8.0)"," density adopted Medium    ",meddens
        if(runonce == 0 .and. meddens > 0 ) iteration_result(1)%med_density = meddens
if(meddens   > 0 )    print *,""

if(oiiitemp >0.2)then
                   print "(A28,F8.0,A1,F8.3)","[O III] temp     Medium    ",oiiitemp, " ",oiiitratio
        if(runonce == 0) iteration_result(1)%OIII_temp = oiiitemp
else if(INT(oiiitemp) == -1)then
                   print "(A28,F8.0,A1,F8.3)","[O III] temp     Medium    ",20000.0, " ",oiiitratio
        if(runonce == 0) iteration_result(1)%OIII_temp = 20000
else
endif

if(neiiitemp>0.2)then
                   print "(A28,F8.0,A1,F8.3)","[Ne III] temp    Medium    ",neiiitemp, " ",neiiitratio
        if(runonce == 0) iteration_result(1)%NeIII_temp = neiiitemp
else if(INT(neiiitemp) == -1)then
                   print "(A28,F8.0,A1,F8.3)","[Ne III] temp    Medium    ",20000.0, " ",neiiitratio
        if(runonce == 0) iteration_result(1)%NeIII_temp = 20000
else
endif
if(ariiitemp>0.2)then
                   print "(A28,F8.0,A1,F8.3)","[Ar III] temp    Medium    ",ariiitemp, " ",ariiitratio
        if(runonce == 0) iteration_result(1)%ArIII_temp = ariiitemp
else if(INT(ariiitemp) == -1)then
                   print "(A28,F8.0,A1,F8.3)","[Ar III] temp    Medium    ",20000.0, " ",ariiitratio
        if(runonce == 0) iteration_result(1)%ArIII_temp = 20000
else
endif
if(siiitemp > 0.2)then
                   print "(A28,F8.0,A1,F8.3)","[S III] temp     Medium    ",siiitemp, " ",siiitratio
        if(runonce == 0) iteration_result(1)%SIII_temp = siiitemp
else if(int(siiitemp) == -1)then
                   print "(A28,F8.0,A1,F8.3)","[S III] temp     Medium    ",20000.0, " ",siiitratio
        if(runonce == 0) iteration_result(1)%SIII_temp = 20000
endif

if(oiiiIRtemp > 0.2)then
        print "(A28,F8.0,A1,F8.3)","[O III] IR temp  Medium    ",oiiiIRtemp, " ",oiiiIRtratio
        if(runonce == 0) iteration_result(1)%OIII_IR_temp = oiiiIRtemp
else if(int(oiiiIRtemp) == -1)then
        print "(A28,F8.0,A1,F8.3)","[O III] IR temp  Medium    ",20000.0, " ",oiiiIRtratio
        if(runonce == 0) iteration_result(1)%OIII_IR_temp = 20000
endif

if(neiiiIRtemp > 0.2)then
        print "(A28,F8.0,A1,F8.3)","[Ne III] IR temp Medium    ",neiiiIRtemp, " ",neiiiIRtratio
        if(runonce == 0) iteration_result(1)%NeIII_IR_temp = neiiiIRtemp
else if(int(neiiiIRtemp) == -1)then
        print "(A28,F8.0,A1,F8.3)","[Ne III] IR temp Medium    ",20000.0, " ",neiiiIRtratio
        if(runonce == 0) iteration_result(1)%NeIII_IR_temp = 20000
endif

if(medtemp  >0)    print "(A28,F8.0)"," temp adopted    Medium    ",medtemp
        if(runonce == 0 .and. medtemp > 0) iteration_result(1)%med_temp = medtemp
if(medtemp  >0)    print *,""

if(neivdens >0)    print "(A28,F8.0,A1,F8.3)","[Ne IV] density  High      ",neivdens, " ",neivnratio
        if(runonce == 0 .and. neivdens > 0) iteration_result(1)%NeIV_density = neivdens
if(highdens >0)    print "(A28,F8.0)"," density adopted High      ",highdens
        if(runonce == 0 .and. highdens > 0) iteration_result(1)%high_density = highdens
if(highdens >0)    print *,""
if(arvtemp  >0)    print "(A28,F8.0,A1,F8.3)","[Ar V] temp      High      ",arvtemp, " ",arvtratio
        if(runonce == 0 .and. arvtemp > 0) iteration_result(1)%ArV_temp = arvtemp
if(nevtemp  >0)    print "(A28,F8.0,A1,F8.3)","[Ne V] temp      High      ",nevtemp, " ",nevtratio
        if(runonce == 0 .and. nevtemp > 0) iteration_result(1)%NeV_temp = nevtemp
if(hightemp >0)    print "(A28,F8.0)"," temp adopted    High      ",hightemp
        if(runonce == 0 .and. hightemp > 0) iteration_result(1)%high_temp = hightemp

! later, make this check with user whether to adopt these values

!      print *,"Enter an option:"
!      print *,"1. Use these diagnostics"
!      print *,"2. Input your own"
!
!      read (5,*) opt
!      if (opt .ne. 1) then
!        print *,"Input low-ionisation zone density: "
!        read (5,*) lowdens
!        print *,"Input low-ionisation zone temperature: "
!        read (5,*) lowtemp
!        print *,"Input medium-ionisation zone density: "
!        read (5,*) meddens
!        print *,"Input medium-ionisation zone temperature: "
!        read (5,*) medtemp
!        print *,"Input high-ionisation zone density: "
!        read (5,*) highdens
!        print *,"Input high-ionisation zone temperature: "
!        read (5,*) hightemp
!      endif

! Helium abundances

        print *,""
        print *,"Ionic abundances"
        print *,"=========="

        print *,"Helium"
        print *,"------"

        call get_helium(REAL(medtemp),REAL(meddens),REAL(He_lines(1)%int_dered),REAL(He_lines(2)%int_dered),REAL(He_lines(3)%int_dered),REAL(He_lines(4)%int_dered),heiabund,heiiabund,Hetotabund, A4471, A4686, A6678, A5876)

if(A4471 > 0)   print "(1x,A17,F6.4)", " He+ (4471)/H+ = ", A4471
if(A5876 > 0)        print "(1x,A17,F6.4)", " He+ (5876)/H+ = ", A5876
if(A6678 > 0)        print "(1x,A17,F6.4)", " He+ (6678)/H+ = ", A6678
if(A4686 > 0)        print "(1x,A17,F6.4)", "He++ (4686)/H+ = ", A4686

        if( (A4471 > 0 .or. A5876 > 0 ) .or. A6678 > 0)then

                if(He_lines(2)%intensity > 0) w1 = 1/((He_lines(2)%int_err / He_lines(2)%intensity)**2)
                if(He_lines(3)%intensity > 0) w2 = 1/((He_lines(3)%int_err / He_lines(3)%intensity)**2)
                if(He_lines(4)%intensity > 0) w3 = 1/((He_lines(4)%int_err / He_lines(4)%intensity)**2)

                !PRINT*, w1, " ", w2, " ", w3

                heiabund = (w1*A4471 + w2*A5876 + w3*A6678)/(w1+w2+w3)

        else

                heiabund = 0.0
        endif

        print "(1X,A17,F6.4)", "        He+/H+ = ",heiabund
        print "(1X,A17,F6.4)", "       He++/H+ = ",heiiabund
        print "(1X,A17,F6.4)", "          He/H = ",heiabund + heiiabund

        w1=0
        w2=0
        w3=0
        w4=0


! get abundances for all CELs

        print *,""
        print *,"CELs"
        print *,"----"
        print *,"Ion         I(lambda)    Abundance"


        !This routine is too simple. I have been changing the temperatures /densities which are input to each zone to disable the zone schtick.
        !Make a better routine that allows using or not using the zone thing.. Its not always appropriate.


        !if(oiiitemp > 0 )then
        !        medtemp = oiiitemp
        !        siiitemp = oiiitemp
        !endif

        !if(int(siiitemp) == -1) siiitemp = oiiitemp


        do i = 1,Iint !This used to be Iint-1 but I think that's corrected in the file reading routine now (RW 25/10/2011)
!                 print *,ILs(i)%ion,ILs(i)%transition,ILs(i)%int_dered
           if (ILs(i)%zone .eq. "low ") then
                !PRINT*, siiitemp, lowdens
                 call get_abundance(ILs(i)%ion, ILs(i)%transition, lowtemp, lowdens,ILs(i)%int_dered, ILs(i)%abundance)
                 ! elseif ( ( i== 47 .or. (i == 46 .or. i == 28 ) ) .and. siiitemp > 1.0 ) then
          !       call get_abundance(ILs(i)%ion, ILs(i)%transition, siiitemp, meddens,ILs(i)%int_dered, ILs(i)%abundance)
                !this makes the code use siii temperatures for siii
                ! print*, "using this bit"
           elseif (ILs(i)%zone .eq. "med ") then
                 call get_abundance(ILs(i)%ion, ILs(i)%transition, medtemp, meddens,ILs(i)%int_dered, ILs(i)%abundance)
           elseif (ILs(i)%zone .eq. "high") then
                 call get_abundance(ILs(i)%ion, ILs(i)%transition, hightemp, highdens,ILs(i)%int_dered, ILs(i)%abundance)
           endif
                 if ((ILs(i)%abundance .ge. 1e-10) .and. (ILs(i)%abundance .lt. 10 ) ) then
                       PRINT "(1X, A11, 1X, F8.3, 5X, ES10.4)",ILs(i)%name,ILs(i)%int_dered,ILs(i)%abundance
                 elseif( (ILs(i)%abundance .ge. 10 ) .or. (ILs(i)%abundance .lt. 1E-10 ) )then
                         ILs(i)%abundance = 0
                 endif
        enddo

! calculate averages

        celabundtemp = 0.
		niiCELabund = 0.
        weight = 0.
        do i= get_ion("nii5754    ", ILs, Iint), get_ion("nii6584    ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-10) niiCELabund = niiCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-10) weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
        enddo
        if (weight .ge. 1e-20) then
          niiCELabund = niiCELabund / weight
        else
          niiCELabund = 0.0
        endif

        niiiIRCELabund = ILs( get_ion("niii57um   ", ILs, Iint)  )%abundance
        niiiUVCELabund = ILs( get_ion("niii1751   ", ILs, Iint)   )%abundance

        if (niiiIRCELabund .ge. 1e-20 .and. niiiUVCELabund .ge. 1e-20) then
          niiiCELabund = (niiiIRCELabund + niiiUVCELabund)/2
        elseif (niiiIRCELabund .ge. 1e-20) then
          niiiCELabund = niiiIRCELabund
        elseif (niiiUVCELabund .ge. 1e-20) then
          niiiCELabund = niiiUVCELabund
        else
          niiiCELabund = 0
        endif

		nivCELabund = 0.
        do i= get_ion("niv1483    ", ILs, Iint), get_ion("niv1485b   ", ILs, Iint) ! would screw up if blend and non blends were both given
          if (ILs(i)%abundance .ge. 1e-20) nivCELabund = nivCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
        enddo
        if (weight .ge. 1e-20) then
          nivCELabund = nivCELabund / weight
        else
          nivCELabund = 0.0
        endif

        nvCELabund = ILs(get_ion("nv1240     ",ILs,Iint))%abundance

        !OII CEL routine fixed. DJS 23/11/10

        if(ILs(get_ion("oii3728b   ", ILs, Iint))%int_dered > 0.0)then
                !calc abundance from doublet blend
                oiiCELabund = ILs(get_ion("oii3728b   ", ILs, Iint))%abundance

        else if(ILs(get_ion("oii3729    ", ILs, Iint))%int_dered > 0.0 .and. ILs(get_ion("oii3726    ", ILs, Iint))%int_dered > 0.0 )then
                !calc abundance from doublet
                w1 = 1/(( ILs(get_ion("oii3729    ", ILs, Iint))%int_err / ILs(get_ion("oii3729    ", ILs, Iint))%intensity   )**2)
                w2 = 1/(( ILs(get_ion("oii3726    ", ILs, Iint))%int_err / ILs(get_ion("oii3726    ", ILs, Iint))%intensity   )**2)

                oiiCELabund = (w1*ILs(get_ion("oii3729    ", ILs, Iint))%abundance + w2*ILs(get_ion("oii3726    ", ILs, Iint))%abundance)/(w1+w2)


        else if((ILs(get_ion("oii3728b   ", ILs, Iint))%int_dered == 0.0 .and. (ILs(get_ion("oii3729    ", ILs, Iint))%int_dered ==0.0 .and. ILs(get_ion("oii3726    ", ILs, Iint))%int_dered == 0.0 )) .and.  (ILs(get_ion("oii7330b   ", ILs, Iint))%abundance > 0.0 .or. ILs(get_ion("oii7319b   ", ILs, Iint))%abundance > 0.0)  )then
                !calc abundance based on far red blends
                w1 = 1/(( ILs(get_ion("oii7330b   ", ILs, Iint))%int_err / ILs(get_ion("oii7330b   ", ILs, Iint))%intensity   )**2)
                w2 = 1/(( ILs(get_ion("oii7319b   ", ILs, Iint))%int_err / ILs(get_ion("oii7319b   ", ILs, Iint))%intensity   )**2)

                oiiCELabund = (w1*ILs(get_ion("oii7330b   ", ILs, Iint))%abundance + w2*ILs(get_ion("oii7319b   ", ILs, Iint))%abundance)/(w1+w2)


        else if        ((ILs(get_ion("oii3728b   ", ILs, Iint))%int_dered == 0.0 .and. (ILs(get_ion("oii3729    ", ILs, Iint))%int_dered ==0.0 .and. ILs(get_ion("oii3726    ", ILs, Iint))%int_dered == 0.0 )) .and. ( (ILs(get_ion("oii7320    ", ILs, Iint))%abundance > 0.0 .or. ILs(get_ion("oii7319    ", ILs, Iint))%abundance > 0.0) .or.  (ILs(get_ion("oii7330    ", ILs, Iint))%abundance > 0.0 .or. ILs(get_ion("oii7331    ", ILs, Iint))%abundance > 0.0)) )then
                !calc abundance based on far red quadruplet
                if(ILs(get_ion("oii7319    ", ILs, Iint))%int_err > 0) w1 = 1/(( ILs(get_ion("oii7319    ", ILs, Iint))%int_err / ILs(get_ion("oii7319    ", ILs, Iint))%intensity   )**2)
                if(ILs(get_ion("oii7320    ", ILs, Iint))%int_err > 0) w2 = 1/(( ILs(get_ion("oii7320    ", ILs, Iint))%int_err / ILs(get_ion("oii7320    ", ILs, Iint))%intensity   )**2)
                if(ILs(get_ion("oii7330    ", ILs, Iint))%int_err > 0) w3 = 1/(( ILs(get_ion("oii7330    ", ILs, Iint))%int_err / ILs(get_ion("oii7330    ", ILs, Iint))%intensity   )**2)
                if(ILs(get_ion("oii7331    ", ILs, Iint))%int_err > 0) w4 = 1/(( ILs(get_ion("oii7331    ", ILs, Iint))%int_err / ILs(get_ion("oii7320    ", ILs, Iint))%intensity   )**2)

                !if statements stop non existent lines being granted infinite weight 1/(0/0)^2 = infinity, defaults to zero if no line detected which keeps the following calculation honest

                oiiCELabund = (w1*ILs(get_ion("oii7319    ", ILs, Iint))%abundance + w2*ILs(get_ion("oii7320    ", ILs, Iint))%abundance + w3*ILs(get_ion("oii7330    ", ILs, Iint))%abundance + w4*ILs(get_ion("oii7331    ", ILs, Iint))%abundance)/(w1+w2+w3+w4)

        else
                oiiCELabund = 0.0
        endif

        !The above routine for oii replaces the following as it was decided that the weighting scheme only works if the lines are originating from the same energy levels.

!       celabundtemp = 0.
!        weight = 0.
!        if( ILs(get_ion("oii7330b   ", ILs, Iint))%int_dered > 0.0  )then
!                 do i=get_ion("oii3729    ", ILs, Iint), get_ion("oii7330b   ", ILs, Iint)
!                  if (ILs(i)%abundance .gt. 0) oiiCELabund = oiiCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
!                  if (ILs(i)%abundance .gt. 0) weight = weight + 1/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
!                enddo
!                if (weight .gt. 0) then
!                  oiiCELabund = oiiCELabund / weight
!                else
!                  oiiCELabund = 0.0
!                endif
!        elseif( ILs(get_ion("oii7330    ", ILs, Iint))%int_dered >0   ) then
!                do i=get_ion("oii3729    ", ILs, Iint), get_ion("oii3726    ", ILs, Iint)
!                  if (ILs(i)%abundance .gt. 0) oiiCELabund = oiiCELabund + ILs(i)%abundance/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
!                  if (ILs(i)%abundance .gt. 0) weight = weight + 1/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
!                enddo
!                do i=get_ion("oii7320    ", ILs, Iint), get_ion("oii7330    ", ILs, Iint)
!                  if (ILs(i)%abundance .gt. 0) oiiCELabund = oiiCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
!                  if (ILs(i)%abundance .gt. 0) weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
!                enddo
!
!
!                if (weight .gt. 0) then
!                  oiiCELabund = oiiCELabund / weight
!                else
!                  oiiCELabund = 0.0
!                endif
!        else
!                oiiCELabund = 0.0
!        endif

        celabundtemp = 0.
		oiiiCELabund = 0.0
        weight = 0.
        do i=get_ion("oiii4959   ", ILs, Iint), get_ion("oiii5007   ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) oiiiCELabund = oiiiCELabund + ILs(i)%abundance /((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) weight = weight + 1 / ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
        enddo
        if (weight .ge. 1e-20) then
          oiiiCELabund = oiiiCELabund / weight
        else
          oiiiCELabund = 0.0
        endif

        celabundtemp = 0.
		oiiiIRCELabund = 0.0
        weight = 0.
        do i=get_ion("oiii52um   ", ILs, Iint), get_ion("oiii88um   ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) oiiiIRCELabund = oiiiIRCELabund + ILs(i)%abundance / ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
        enddo
        if (weight .ge. 1e-20) then
          oiiiIRCELabund = oiiiIRCELabund / weight
        else
          oiiiIRCELabund = 0.0
        endif

        oivCELabund = ILS( get_ion("oiv25p9um  ", ILS, Iint))%abundance

        neiiIRCELabund = ILs(  get_ion("neii12p8um ", ILs, Iint)  )%abundance
        neiiiIRCELabund = ILs(  get_ion("neiii15p5um ", ILs, Iint)  )%abundance

        celabundtemp = 0.
		neiiiCELabund = 0.
        weight = 0.
        do i=get_ion("neiii3868  ", ILs, Iint), get_ion("neiii3967  ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) neiiiCELabund = neiiiCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) weight = weight + 1/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
        enddo
        if (weight .ge. 1e-20) then
          neiiiCELabund = neiiiCELabund / weight
        else
          neiiiCELabund = 0.0
        endif


        celabundtemp = 0.
		neivCELabund = 0.
        weight = 0.
        do i=get_ion("neiv2423   ", ILs, Iint), get_ion("neiv4725b  ", ILs, Iint) ! would screw up if blends and non blends were given
          if (ILs(i)%abundance .ge. 1e-20) neivCELabund = neivCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
        enddo
        if (weight .ge. 1e-20) then
          neivCELabund = neivCELabund / weight
        else
          neivCELabund = 0.0
        endif

        celabundtemp = 0.
		siiCELabund = 0.
        weight = 0.
        do i=get_ion("sii4068    ", ILs, Iint), get_ion("sii6731    ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) siiCELabund = siiCELabund + ILs(i)%abundance/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
        enddo
        if (weight .ge. 1e-20) then
          siiCELabund = siiCELabund / weight
        else
          siiCELabund = 0.0
        endif

        !siiiCELabund = 0 ! ILs(28)%abundance
        !celabundtemp = 0.
        !weight = 0.
        !do i=get_ion("siii9069   ", ILs, Iint), get_ion("siii9531   ", ILs, Iint)
        !  if (ILs(i)%abundance .gt. 0) siiiCELabund = siiiCELabund + ILs(i)%abundance/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
        !  if (ILs(i)%abundance .gt. 0) weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
        !enddo
             !if (weight .gt. 0) then
        !  siiiCELabund = siiiCELabund / weight
        !else
        !  siiiCELabund = 0.0
        !endif

        ! SIII abundance section previously buggered. SIII 9069 and 9531 doublet special due to absorption lines. See Liu, Barlow etc 1995 (Far Red IR Lines in a PN), one of 9069/9531 is ALWAYS absorbed however the other is then always fine.  We can tell which is is by looking at the ratio 9069/9531.
        if (ILs(get_ion("siii9069   ", ILs, Iint))%abundance .eq. 0 .and. ILs(get_ion("siii9531   ", ILs, Iint))%abundance .eq. 0) then
                siiiCELabund = ILs(get_ion("siii6312   ", ILs, Iint))%abundance
        else !only calculate all the IR SIII telluric absorption if the lines are present.
                siiiCELabund = ILs(get_ion("siii9069   ", ILs, Iint))%int_dered / ILs(get_ion("siii9531   ", ILs, Iint))%int_dered
        !I am using siiiCELabund as a switch for the following if statement, replace this with another variable if you like but I don't think it matters.. (DJS)

                if(siiiCELabund < (1.05 * 0.403) .and. siiiCELabund > (0.90 * 0.403))then !this case should never occur

                        if(ILs(get_ion("siii9069   ", ILs, Iint))%intensity > 0) w1 = 1/(ILs(get_ion("siii9069   ", ILs, Iint))%int_err / ILs(get_ion("siii9069   ", ILs, Iint))%intensity)**2
                        if(ILs(get_ion("siii9531   ", ILs, Iint))%intensity > 0) w2 = 1/(ILs(get_ion("siii9531   ", ILs, Iint))%int_err / ILs(get_ion("siii9531   ", ILs, Iint))%intensity)**2

                        siiiCELabund= ( w1*ILs(get_ion("siii9069   ", ILs, Iint))%abundance + w2*ILs(get_ion("siii9531   ", ILs, Iint))%abundance )/(w1+w2)

                elseif(siiiCELabund > (1.1 * 0.403) )then
                        !9531 absorbed
                        siiiCELabund = ILs( get_ion("siii9069   ", ILs, Iint) )%abundance

                elseif(siiiCELabund < (0.9 * 0.403) )then
                        !9069 absorbed
                        siiiCELabund = ILs( get_ion("siii9531   ", ILs, Iint) )%abundance
                else
                        siiiCELabund=0.0
                endif
        endif

        siiiIRCELabund = ILs( get_ion("siii18p7um ", ILs, Iint)   )%abundance
        sivIRCELabund = ILs(  get_ion("siv10p5um  ", ILs, Iint) )%abundance

        celabundtemp = 0.
		cliiiCELabund = 0.
        weight = 0.
        do i=get_ion("cliii5517  ", ILs, Iint), get_ion("cliii5537  ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) cliiiCELabund = cliiiCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) then
            weight = weight + 1/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          endif
        enddo
        if (weight .ge. 1e-20) then
          cliiiCELabund = cliiiCELabund / weight
        else
          cliiiCELabund = 0.0
        endif

        celabundtemp = 0.
		ariiiCELabund = 0.
        weight = 0.
        do i=get_ion("ariii7135  ", ILs, Iint), get_ion("ariii7751  ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) ariiiCELabund = ariiiCELabund + ILs(i)%abundance/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) then
            weight = weight + 1/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          endif
        enddo
        if (weight .ge. 1e-20) then
          ariiiCELabund = ariiiCELabund / weight
        else
          ariiiCELabund = 0.0
        endif

        celabundtemp = 0.
		arivCELabund = 0.
        weight = 0.
        do i=get_ion("ariv4711   ", ILs, Iint), get_ion("ariv4740   ", ILs, Iint)
        arivCELabund = arivCELabund + ILs(i)%abundance/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) then
            weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          endif
        enddo
        if (weight .ge. 1e-20) then
          arivCELabund = arivCELabund / weight
        else
          arivCELabund = 0.0
        endif

        ariiiIRCELabund = ILs(get_ion("ariii9um   ", ILs, Iint))%abundance
		
        ciiCELabund = ILs(get_ion("cii2325    ", ILs, Iint))%abundance
        civCELabund = ILs(get_ion("civ1548    ", ILs, Iint))%abundance
		
        celabundtemp = 0.
		ciiiCELabund = 0.
        weight = 0.
        do i=get_ion("ciii1907   ", ILs, Iint), get_ion("ciii1909b  ", ILs, Iint) ! would screw up if blend and non-blend were given.
          if (ILs(i)%abundance .ge. 1e-20) then
            ciiiCELabund = ciiiCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
            weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          endif
        enddo
        if (weight .ge. 1e-20) then
          ciiiCELabund = ciiiCELabund / weight
        else
          ciiiCELabund = 0.0
        endif

        celabundtemp = 0.
		neivCELabund = 0.
        weight = 0.
        do i=get_ion("neiv2423   ", ILs, Iint), get_ion("neiv2425   ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) neivCELabund = neivCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) then
            weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          endif
        enddo
        if (weight .ge. 1e-20) then
          neivCELabund = neivCELabund / weight
        else
          neivCELabund = 0.0
        endif

        celabundtemp = 0.
		nevCELabund = 0.
        weight = 0.
        do i=get_ion("nev3345    ", ILs, Iint), get_ion("nev3426    ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) nevCELabund = nevCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) then
            weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          endif
        enddo
        if (weight .ge. 1e-20) then
          nevCELabund = nevCELabund / weight
        else
          nevCELabund = 0.0
        endif

        celabundtemp = 0.
		arvCELabund = 0.
        weight = 0.
        do i=get_ion("arv6435    ", ILs, Iint), get_ion("arv7005    ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) arvCELabund = arvCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) then
            weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          endif
        enddo
        if (weight .ge. 1e-20) then
          arvCELabund = arvCELabund / weight
        else
          arvCELabund = 0.0
        endif

         celabundtemp = 0.
		 ciCELabund = 0.
        weight = 0.
        do i=get_ion("ci9850     ", ILs, Iint), get_ion("ci8727     ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) ciCELabund = ciCELabund + ILs(i)%abundance/ ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) then
            weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          endif
        enddo
        if (weight .ge. 1e-20) then
          ciCELabund = ciCELabund / weight
        else
          ciCELabund = 0.0
        endif

        NCabundCEL = ciCELabund

         celabundtemp = 0.
		 oiCELabund = 0.
        weight = 0.
        do i=get_ion("oi6300     ", ILs, Iint), get_ion("oi5577     ", ILs, Iint)
          if (ILs(i)%abundance .ge. 1e-20) oiCELabund = oiCELabund + ILs(i)%abundance/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          if (ILs(i)%abundance .ge. 1e-20) then
            weight = weight + 1/  ((ILs(i)%int_err/ ILs(i)%intensity)  **2)
          endif
        enddo
        if (weight .ge. 1e-20) then
          oiCELabund = oiCELabund / weight
        else
          oiCELabund = 0.0
        endif

        NOabundCEL = oiCELabund

! now get abundances for ORLs
! o2+
       call oii_rec_lines(oiiiTemp,oiiDens,DBLE(1),oiiRLs)

       do i = 1,listlength
         do j = 1,415
          if (abs(linelist(i)%wavelength-oiiRLs(j)%Wave) .le. 0.005) then
            oiiRLs(j)%Obs = linelist(i)%int_dered
            oiiRLs(j)%abundance = oiiRLs(j)%obs/oiiRLs(j)%Int
          endif
         enddo
       enddo

!N2+

       call nii_rec_lines(oiiiTemp,oiiDens,DBLE(1),niiRLs)

       do i = 1,listlength
         do j = 1,99
          if (abs(linelist(i)%wavelength-niiRLs(j)%Wave) .le. 0.005) then
            niiRLs(j)%Obs = linelist(i)%int_dered
            niiRLs(j)%abundance = niiRLs(j)%obs/niiRLs(j)%Int
          endif
         enddo
       enddo

!C2+
       call cii_rec_lines(oiiiTemp,oiiDens,DBLE(1),ciiRLs)

       do i = 1,listlength
         do j = 1,57
          if (abs(linelist(i)%wavelength-ciiRLs(j)%Wave) .le. 0.005) then
            ciiRLs(j)%Obs = linelist(i)%int_dered
            ciiRLs(j)%abundance = ciiRLs(j)%obs/ciiRLs(j)%Int
          endif
         enddo
       enddo

!Ne2+
       call neii_rec_lines(oiiiTemp,oiiDens,DBLE(1),neiiRLs)

       do i = 1,listlength
         do j = 1,38
          if (abs(linelist(i)%wavelength-neiiRLs(j)%Wave) .le. 0.005) then
            neiiRLs(j)%Obs = linelist(i)%int_dered
            neiiRLs(j)%abundance = neiiRLs(j)%obs/neiiRLs(j)%Int
          endif
         enddo
       enddo

!C3+, N3+
       call xiii_rec_lines(oiiiTemp,oiiDens,DBLE(1),xiiiRLs)

       do i = 1,listlength
         do j = 1,6
          if (abs(linelist(i)%wavelength-xiiiRLs(j)%Wave) .le. 0.005) then
            xiiiRLs(j)%Obs = linelist(i)%int_dered
            xiiiRLs(j)%abundance = xiiiRLs(j)%obs/xiiiRLs(j)%Int
          endif
         enddo
       enddo

      print *,""
      print *,"Recombination lines"
      print *,"-------------------"

      rlabundtemp = 0.0
      weight = 0.0

!cii recombination lines

      do i = 1,57
        if (ciiRLs(i)%abundance .ge. 1e-20) then
!          print "(1X,F7.2,1X,F6.3,1X,ES9.3)",ciiRLs(i)%wave,ciiRLs(i)%obs,ciiRLs(i)%abundance
          rlabundtemp = rlabundtemp + ciiRLs(i)%obs
          weight = weight + ciiRLs(i)%Int
        endif
        if (ciiRLs(i)%wave .eq. 4267.15D0) then
          cii4267rlabund = ciiRLs(i)%abundance
        endif
      enddo

      if (weight .gt. 0) then
        ciirlabund = rlabundtemp/weight
        print *,""
        print *,"CII"
        print *,"lambda   Int   Abund"
        print "(A34,ES9.3)","Abundance (all lines co-added): ",ciirlabund
        print "(A34,ES9.3)","Abundance (4267 line only):     ",cii4267rlabund
      else
        ciirlabund = 0.
        print *,"No CII recombination lines"
      endif

!nii recombination lines

!      print *,"lambda   Mult   Int   Abund"
      do i = 1,99
        if (niiRLs(i)%abundance .ge. 1e-20) then
!          print "(F7.2,1X,A7,1X,F6.3,1X,ES9.3)",niiRLs(i)%wave,niiRLs(i)%Mult,niiRLs(i)%obs,niiRLs(i)%abundance
          rlabundtemp = rlabundtemp + niiRLs(i)%obs
          weight = weight + niiRLs(i)%Int
        endif
      enddo

  if (weight .gt. 0) then
      print *,""
      print *,"NII"

      print *,"Abundance from co-added intensity: "
      print "(ES9.2)",rlabundtemp / weight

      niimultiplets%Multiplet = (/"V3     ","V5     ","V8     " ,"V12    ","V20    ","V28    ","3d-4f  "/)

! get multiplet abundances from coadded intensity

      print *,"Mult    Intensity   N2+/H+"

      do j = 1,6
        rlabundtemp = 0.
        weight = 1.
        do i = 1,99
          if (niiRLs(i)%Mult .eq. niimultiplets(j)%Multiplet .and. niiRLs(i)%obs .gt. 0) then
!            rlabundtemp = rlabundtemp + (niiRLs(i)%obs * niiRLs(i)%abundance)
!            weight = weight + niiRLs(i)%obs
             rlabundtemp = rlabundtemp + niiRLs(i)%obs
             weight = weight + niiRLs(i)%Int
          endif
        enddo
        print "(1X,A7,F6.3,7X,ES9.3)",niimultiplets(j)%Multiplet,rlabundtemp, rlabundtemp/weight
        niimultiplets(j)%Abundance = rlabundtemp/weight
      enddo

      rlabundtemp = 0.
      weight = 0.
      do i = 77,99
        if (niiRLs(i)%obs .gt. 0) then
!          rlabundtemp = rlabundtemp + (niiRLs(i)%obs * niiRLs(i)%abundance)
!          weight = weight + niiRLs(i)%obs
           rlabundtemp = rlabundtemp + niiRLs(i)%obs
           weight = weight + niiRLs(i)%Int
        endif
      enddo

      if (isnan((rlabundtemp/weight))) then
      niimultiplets(7)%abundance = 0
      else
      niimultiplets(7)%abundance = rlabundtemp/weight
      endif

      print "(1X,A7,F6.3,7X,ES9.3)",niimultiplets(7)%Multiplet,rlabundtemp, niimultiplets(7)%abundance
!      print "(F6.3,16X,ES9.3)",rlabundtemp, rlabundtemp/weight

      rlabundtemp = 0.0
      weight = 0
      do i = 1,7
        rlabundtemp = rlabundtemp + niimultiplets(i)%abundance
        if (niimultiplets(i)%abundance .ge. 1e-20) then
          weight = weight + 1
        endif
      enddo

      print *,"Abundance - mean of each multiplet's abundance:"
      niiRLabund = rlabundtemp/weight
      print "(ES9.3)",niiRLabund
  else
    print *,"No NII recombination lines"
  endif

!oii recombination lines

      rlabundtemp = 0.00
      weight = 0.00

!      print *,"lambda   Mult   Int   Abund"
      do i = 1,415
        if (oiiRLs(i)%abundance .ge. 1e-20) then
!          print "(F7.2,1X,A7,1X,F6.3,1X,ES9.3)",oiiRLs(i)%wave,oiiRLs(i)%Mult,oiiRLs(i)%obs,oiiRLs(i)%abundance
          rlabundtemp = rlabundtemp + oiiRLs(i)%obs
          weight = weight + oiiRLs(i)%Int
        endif
      enddo

  if (weight .gt. 0) then

      print *,""
      print *,"OII"


      print *,"Abundance from co-added intensity: "
      print "(ES9.2)",rlabundtemp/weight

      oiimultiplets%Multiplet = (/" V1    "," V2    "," V5    " ," V10   "," V11   "," V12   "," V19   "," V20   "," V25   "," V28   "," V33   "," 3d-4f "/)

! get multiplet abundances from coadded intensity

      print *,"Co-added intensity   O2+/H+"

      do j = 1,11
        rlabundtemp = 0.
        weight = 0.
        do i = 1,415
          if (oiiRLs(i)%Mult .eq. oiimultiplets(j)%Multiplet .and. oiiRLs(i)%obs .gt. 0) then
!            rlabundtemp = rlabundtemp + (oiiRLs(i)%obs * oiiRLs(i)%abundance)
!            weight = weight + oiiRLs(i)%obs
             rlabundtemp = rlabundtemp + oiiRLs(i)%obs
             weight = weight + oiiRLs(i)%Int
          endif
        enddo
        if (weight .gt. 0) then
          oiimultiplets(j)%Abundance = rlabundtemp/weight
        else
          oiimultiplets(j)%Abundance = 0.0
        endif
        print "(1X,A7,F6.3,7X,ES9.3)",oiimultiplets(j)%Multiplet,rlabundtemp,oiimultiplets(j)%abundance
      enddo

      rlabundtemp = 0.
      weight = 0.
      do i = 1,182
        if (oiiRLs(i)%Mult .ne. "       " .and. oiiRLs(i)%obs .gt. 0) then
!          rlabundtemp = rlabundtemp + (oiiRLs(i)%obs * oiiRLs(i)%abundance)
!          weight = weight + oiiRLs(i)%obs
           rlabundtemp = rlabundtemp + oiiRLs(i)%obs
           weight = weight + oiiRLs(i)%Int
        endif
      enddo

      if ( isnan( (rlabundtemp/weight) ) ) then
      oiimultiplets(12)%abundance = 0
      else
      oiimultiplets(12)%abundance = rlabundtemp/weight
      endif

      print "(1X,A7,F6.3,7X,ES9.3)",oiimultiplets(j)%Multiplet,rlabundtemp, rlabundtemp/weight
!      print *,"3d-4f :"
!      print *,"Co-added intensity   O2+/H+"
!      print "(F6.3,16X,ES9.3)",rlabundtemp, rlabundtemp/weight

      rlabundtemp = 0.0
      weight = 0
      do i = 1,7
        rlabundtemp = rlabundtemp + oiimultiplets(i)%abundance
        if (oiimultiplets(i)%abundance .ge. 1e-20) then
          weight = weight + 1
        endif
      enddo

      print *,"Abundance - mean of each multiplet's abundance:"
      oiiRLabund = rlabundtemp/weight
      print "(ES9.3)",oiiRLabund
   else
      print *,"No OII recombination lines"
   endif

!neii recombination lines

      rlabundtemp = 0.0
      weight = 0.0

!      print *,"lambda   Mult   Int   Abund"
      do i = 1,38
        if (neiiRLs(i)%abundance .ge. 1e-20) then
!          print "(F7.2,1X,F6.3,1X,ES9.3)",neiiRLs(i)%wave,neiiRLs(i)%obs,neiiRLs(i)%abundance
           rlabundtemp = rlabundtemp + neiiRLs(i)%obs
           weight = weight + neiiRLs(i)%Int
        endif
      enddo

   if (weight .gt. 0) then
      print *,""
      print *,"NeII"

      neiiRLabund = rlabundtemp/weight

      print *,"Abundance from co-added intensities: "
      print "(ES9.3)",neiiRLabund
   else
      print *,"No NeII recombination lines"
   endif

      rlabundtemp = 0.0
      weight = 0.0
      print *,""
      print *,"CIII"
      print *,"lambda   Mult   Int   Abund"
      do i = 1,4
        if (xiiiRLs(i)%abundance .ge. 1e-20) then
          print "(F7.2,1X,F6.3,1X,ES9.3)",xiiiRLs(i)%wave,xiiiRLs(i)%obs,xiiiRLs(i)%abundance
          rlabundtemp = rlabundtemp + xiiiRLs(i)%obs
          weight = weight + xiiiRLs(i)%Int
        endif
      enddo
      if (weight .gt. 0) then
        ciiiRLabund = rlabundtemp / weight
      else
        print *,"No CIII recombination lines"
        ciiiRLabund = 0.0
      endif

      print *,""
      print *,"NIII"
      print *,"lambda   Mult   Int   Abund"
      do i = 5,6
        if (xiiiRLs(i)%abundance .ge. 1e-20) then
           print "(F7.2,1X,F6.3,1X,ES9.3)",xiiiRLs(i)%wave,xiiiRLs(i)%obs,xiiiRLs(i)%abundance
        endif
      enddo

     if (xiiiRLs(6)%abundance .ge. 1e-20) then
        niiiRLabund = xiiiRLs(6)%abundance
     else
        niiiRLabund = 0.0
        print *,"No NIII recombination lines"
     endif

! ICFs (Kingsburgh + Barlow 1994)

! oxygen - complete
     OabundCEL = 0.
        if (oiiCELabund .ge. 1e-20 .and. oiiiCELabund .ge. 1e-20 .and. oivCELabund .ge. 1e-20 .and. nvCELabund .ge. 1e-20)then ! O3+ and N4+
                fn4 = (nvCELabund)/(niiCELabund + niiiCELabund + nivCELabund + nvCELabund) !A4
                CELicfO = 1./(1.-0.95*fn4)                                                 !A5
                OabundCEL = CELicfO * (oiiCELabund + oiiiCELabund + oivCELabund)           !A6
        elseif (oiiCELabund .ge. 1e-20 .and. oiiiCELabund .ge. 1e-20 .and. oivCELabund .ge. 1e-20 .and. nvCELabund .lt. 1e-20) then ! O3+ but no N4+
                CELicfO = 1
                OabundCEL = oiiCELabund + oiiiCELabund + oivCELabund !sum of visible ionisation stages
        elseif (oiiCELabund .ge. 1e-20 .and. oiiiCELabund .ge. 1e-20 .and. oivCELabund .lt. 1e-20 .and. nvCELabund .ge. 1e-20) then !no O3+ but N4+
                CELicfO = (niiCELabund + niiiCELabund + nivCELabund + nvCELabund) / (niiCELabund + niiiCELabund) ! A7
                OabundCEL = CELicfO * (oiiCELabund + oiiiCELabund)                                              ! A8
        elseif (oiiCELabund .ge. 1e-20 .and. oiiiCELabund .ge. 1e-20 .and. oivCELabund .lt. 1e-20 .and. nvCELabund .lt. 1e-20)then !no O3+ or N4+ seen
                CELicfO = ((heiabund + heiiabund)/heiabund)**(2./3.) !KB94 A9
                OabundCEL = CELicfO * (oiiCELabund + oiiiCELabund) !A10 
        endif

! nitrogen - complete
     NabundCEL = 0.
     if (niiCELabund .ge. 1e-20 .and. niiiUVCELabund .ge. 1e-20 .and. nivCELabund .ge. 1e-20) then !all ionisation stages seen
       CELicfN = 1.
       NabundCEL = niiCELabund + niiiCELabund + nivCELabund
     elseif (niiCELabund .ge. 1e-20 .and. niiiUVCELabund .lt. 1e-20 .and. nivCELabund .ge. 1e-20) then !no N2+ seen
       CELicfN = 1.5
       NabundCEL = 1.5*(niiCELabund + nivCELabund)
     elseif (niiCELabund .ge. 1e-20 .and. niiiUVCELabund .lt. 1e-20 .and. nivCELabund .lt. 1e-20) then !Only N+ seen
       CELicfN = OabundCEL/oiiCELabund
       NabundCEL = niiCELabund * CELicfN
     endif

! carbon - complete
     CabundCEL = 0.
     if (ciiCELabund .ge. 1e-20 .and. ciiiCELabund .ge. 1e-20 .and. civCELabund .ge. 1e-20 .and. heiiabund .lt. 1e-20) then !No C4+ but all other seen
       CELicfC = 1.
       CabundCEL = ciiCELabund + ciiiCELabund + civCELabund
     elseif (ciiCELabund .lt. 1e-20 .and. ciiiCELabund .ge. 1e-20 .and. civCELabund .ge. 1e-20 .and. heiiabund .lt. 1e-20) then !No C4+, and no CII lines seen
       CELicfC = (oiiCELabund + oiiiCELabund) / oiiiCELabund !A11
       CabundCEL = CELicfC * (ciiCELabund + ciiiCELabund) !A12
     elseif (ciiCELabund .lt. 1e-20 .and. ciiiCELabund .ge. 1e-20 .and. civCELabund .lt. 1e-20 .and. oiiiCELabund .ge. 1e-20) then !Only C2+ seen, but O2+ also seen
       CELicfC = OabundCEL/oiiiCELabund !A13
       CabundCEL = CELicfC * ciiiCELabund !A14
     elseif (nvCELabund .ge. 1e-20 .and. heiiabund .ge. 1e-20) then !N4+ and He2+
       fn4 = (nvCELabund)/(niiCELabund + niiiCELabund + nivCELabund + nvCELabund) !A4, A15 
       if (fn4 .lt. 0.29629) then !condition in KB94 is if icf(C)>5, but eqn A16 can go negative at high fn4 so this is a better check for the high-excitation case
         CELicfC = 1/(1-(2.7*fn4))!A16
       else
         CELicfC = (niiCELabund + niiiCELabund + nivCELabund + nvCELabund) / (niiCELabund + niiiCELabund + nivCELabund) !A18
       endif
       CabundCEL = CELicfC * (ciiCELabund + ciiiCELabund + civCELabund) !A19
     elseif (ciiCELabund .ge. 1e-20 .and. ciiiCELabund .ge. 1e-20 .and. civCELabund .ge. 1e-20 .and. heiiabund .ge. 1e-20 .and. nvCELabund .lt. 1e-20) then !PN is hot enough for He2+ but not for N4+
        CELicfC = ((heiiabund + heiabund)*heiabund)**(1./3.) !A20
        CabundCEL = CELicfC * (ciiCELabund + ciiiCELabund + civCELabund) !A21
     elseif (ciiCELabund .lt. 1e-20 .and. ciiiCELabund .ge. 1e-20 .and. civCELabund .ge. 1e-20) then !C+ not seen
        CELicfC = 1/(1 - (niiCELabund/NabundCEL) - 2.7*(nvCELabund/NabundCEL)) !A22
        if (CELicfC .gt. 5) then !if ICF is greater than 5
           CELicfC = (niiCELabund + niiiCELabund + nivCELabund + nvCELabund)/(niiiCELabund + nivCELabund) !A23
        endif
        CabundCEL = CELicfC * (ciiiCELabund+ civCELabund) !A24
     elseif (ciiCELabund .ge. 1e-20 .and. ciiiCELabund .ge. 1e-20 .and. civCELabund .ge. 1e-20 .and. heiiabund .ge. 1e-20 .and. (nivCELabund .lt. 1e-20 .or. nvCELabund .lt. 1e-20)) then !final case i think.
        CELicfC = ((oiiCELabund + oiiiCELabund)/oiiiCELabund)*((heiiabund + heiabund)*heiabund)**(1./3.) !A25
        CabundCEL = CELicfC * (ciiCELabund + ciiiCELabund + civCELabund) !A26
     endif

! Neon - complete
     NeabundCEL = 0.
     if (neiiiCELabund .ge. 1e-20 .and. neivCELabund .ge. 1e-20 .and. nevCELabund .ge. 1e-20) then !all stages seen
       CELicfNe = 1.
       NeabundCEL = neiiiCELabund + neivCELabund + nevCELabund
     elseif (neiiiCELabund .ge. 1e-20 .and. neivCELabund .lt. 1e-20 .and. nevCELabund .ge. 1e-20) then !no Ne IV seen
       CELicfNe = 1.5
       NeabundCEL = CELicfNe * (neiiiCELabund + nevCELabund) !KB94 A27
     elseif (neiiiCELabund .ge. 1e-20 .and. neivCELabund .lt. 1e-20 .and. nevCELabund .lt. 1e-20) then !Only Ne2+ seen
       CELicfNe = OabundCEL / oiiiCELabund !KB94 A28
       NeabundCEL = CELicfNe * neiiiCELabund
     endif

! Argon - complete
     ArabundCEL = 0.
     if (ariiiCELabund .ge. 1e-20 .and. arivCELabund .lt. 1e-20 .and. arvCELabund .lt. 1e-20) then !only Ar2+ seen
       CELicfAr = 1.87 !KB94 A32
       ArabundCEL = CELicfAr * ariiiCELabund !KB94 A33
     elseif (ariiiCELabund .lt. 1e-20 .and. arivCELabund .ge. 1e-20 .and. arvCELabund .lt. 1e-20) then !Only Ar3+ seen
       CELicfAr = NeabundCEL / neiiiCELabund !KB94 A34
       ArabundCEL = CELicfAr * arivCELabund !KB94 A35
     elseif (ariiiCELabund .ge. 1e-20 .and. arivCELabund .ge. 1e-20) then !Ar 2+ and 3+ seen
       CELicfAr = 1./(1.-(niiCELabund/NabundCEL))
       ArabundCEL = ariiiCELabund + arivCELabund + arvCELabund !KB94 A31
     endif

! Sulphur
     SabundCEL = 0.
     if (siiCELabund .ge. 1e-20 .and. siiiCELabund .ge. 1e-20 .and. sivIRCELabund .lt. 1e-20) then !both S+ and S2+
       CELicfS = (1 - (  (1-(oiiCELabund/OabundCEL))**3.0  )   )**(-1.0/3.0) !KB94 A36 
       SabundCEL = CELicfS * (siiCELabund + siiiCELabund) !KB94 A37
     elseif (siiCELabund .ge. 1e-20 .and. siiiCELabund .ge. 1e-20 .and. sivIRCELabund .ge. 1e-20) then !all states observed
       CELicfS = 1.
       SabundCEL = siiCELabund + siiiCELabund + sivIRCELabund
     elseif (siiCELabund .ge. 1e-20 .and. siiiCELabund .lt. 1e-20 .and. sivIRCELabund .lt. 1e-20) then !Only S+ observed
       CELicfS = (((oiiiCELabund/oiiCELabund)**0.433) * 4.677) * (1-(1-((oiiCELabund/OabundCEL)**3)))**(-1./3.) ! KB94 A37 with S2+/S+ from A38
       SabundCEL = CELicfS * siiCELabund
     endif

!very high excitation cases, all He is doubly ionised

     if (heiabund .lt. 1e-20 .and. heiiabund .ge. 1e-20) then
       CELicfO = NeabundCEL / neiiiCELabund                              !A39
       CELicfC = CELicfO                                                 !A39
       OabundCEL = CELicfO * (oiiCELabund + oiiiCELabund + oivCELabund)  !A40
       CabundCEL = CELicfC * (ciiiCELabund + civCELabund)                !A41
     endif

!Chlorine - not included in KB94, this prescription is from Liu et al. (2000)
     ClabundCEL = 0.
    if (cliiiCELabund .ge. 1e-20 .and. siiiCELabund .ge. 1e-20) then
       CELicfCl = SabundCEL/siiiCELabund
       ClabundCEL = CELicfCl * cliiiCELabund
    endif

!ORLs
!Oxygen

     if (oiiRLabund .ge. 1e-20) then
       RLicfO = ((heiabund + heiiabund)/heiabund)**(2./3.) * (1+(oiiCELabund/oiiiCELabund))
       OabundRL = RLicfO * oiiRLabund
     else
       RLicfO = 1.0
       OabundRL = 0
     endif

!Nitrogen

     RLicfN = 1.0
     NabundRL = niiRLabund + niiiRLabund

!Carbon

     RLicfC = 1.0
     CabundRL = ciiRLabund + ciiiRLabund

!Neon

     if (oiiRLabund .ge. 1e-20) then
       RLicfNe = OabundRL / oiiRLabund
       NeabundRL = RLicfNe * neiiRLabund
     else
       RLicfNe = 1.0
       NeabundRL = 0.0
     endif

!finish these TODO

!Printout edited to include weighted averages of Ionic species as these are neccessary for paper tables. DJS

print *,""
print *,"Total abundances"
print *,"================"
print *,""

print *,"CELs"
print *,""
print *,"Element           ICF     X/H"
print *,"-------           ---     ---"
!carbon
if(NCabundCEL > 0) print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," Neutral Carbon ",0.0,NCabundCEL,12+log10(NCabundCEL)
        if(runonce == 0 .and. NCabundCEL > 0) iteration_result(1)%NC_abund_CEL = NCabundCEL
if(ciiCELabund > 0) print "(A24,ES8.2)"                ,"  C+/H+                 ",ciiCELabund
        if(runonce == 0 .and. ciiCELabund> 0) iteration_result(1)%cii_abund_CEL = ciiCELabund
if(ciiiCELabund > 0) print "(A24,ES8.2)"               ,"  C++/H+                ",ciiiCELabund
        if(runonce == 0 .and. ciiiCELabund> 0) iteration_result(1)%ciii_abund_CEL = ciiiCELabund
if(civCELabund > 0) print "(A24,ES8.2)"                ,"  C+++/H+               ",civCELabund
        if(runonce == 0 .and. civCELabund> 0) iteration_result(1)%civ_abund_CEL = civCELabund
if(CabundCEL > 0)  print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," Carbon         ",CELicfC,CabundCEL,12+log10(CabundCEL)
        if(runonce == 0 .and. CabundCEL > 0) iteration_result(1)%C_abund_CEL = CabundCEL
!nitrogen
if(niiCELabund > 0) print "(A24,ES8.2)"                ,"  N+/H+                 ",niiCELabund
        if(runonce == 0 .and. niiCELabund > 0) iteration_result(1)%Nii_abund_CEL = niiCELabund
if(niiiCELabund > 0) print "(A24,ES8.2)"               ,"  N++/H+                ",niiiCELabund
        if(runonce == 0 .and. niiiCELabund > 0) iteration_result(1)%Niii_abund_CEL = niiiCELabund
if(nivCELabund > 0) print "(A24,ES8.2)"                ,"  N+++/H+               ",nivCELabund
        if(runonce == 0 .and. nivCELabund > 0) iteration_result(1)%Niv_abund_CEL = nivCELabund
if(nvCELabund > 0) print "(A24,ES8.2)"                ,"  N++++/H+              ",nvCELabund
        if(runonce == 0 .and. nvCELabund > 0) iteration_result(1)%Nv_abund_CEL = nvCELabund
if(NabundCEL > 0)  print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," Nitrogen       ",CELicfN,NabundCEL,12+log10(NabundCEL)
        if(runonce == 0 .and. NabundCEL > 0) iteration_result(1)%N_abund_CEL = NabundCEL
!oxygen
if(NOabundCEL > 0) print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," Neutral Oxygen ",0.0,NOabundCEL,12+log10(NOabundCEL)
        if(runonce == 0 .and. NOabundCEL > 0) iteration_result(1)%NO_abund_CEL = NOabundCEL
if(oiiCELabund >0) print "(A24,ES8.2)"                , "  O+/H+                 ",oiiCELabund
        if(runonce == 0 .and. oiiCELabund >0) iteration_result(1)%Oii_abund_CEL = oiiCELabund
if(oiiiCELabund >0) print "(A24,ES8.2)"               , "  O++/H+                ",oiiiCELabund
        if(runonce == 0 .and. oiiiCELabund >0) iteration_result(1)%Oiii_abund_CEL = oiiiCELabund
if(oivCELabund > 0) print "(A24,ES8.2)"                ,"  O+++/H+               ",oivCELabund
        if(runonce == 0 .and. oivCELabund > 0) iteration_result(1)%Oiv_abund_CEL = oivCELabund
if(OabundCEL > 0)  print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," Oxygen         ",CELicfO,OabundCEL,12+log10(OabundCEL)
        if(runonce == 0 .and. OabundCEL > 0) iteration_result(1)%O_abund_CEL = OabundCEL
!neon
if(neiiIRCELabund > 0) print "(A24,ES8.2)"                ,"  Ne+/H+                ",neiiIRCELabund
        if(runonce == 0 .and. neiiIRCELabund > 0) iteration_result(1)%Neii_abund_CEL = neiiIRCELabund
if(neiiiCELabund >0) print "(A24,ES8.2)"               , "  Ne++/H+               ",neiiiCELabund
        if(runonce == 0 .and. neiiiCELabund >0) iteration_result(1)%Neiii_abund_CEL = neiiiCELabund
if(neivCELabund >0)  print "(A24,ES8.2)"               , "  Ne+++/H+              ",neivCELabund
        if(runonce == 0 .and. neivCELabund >0) iteration_result(1)%Neiv_abund_CEL = neivCELabund
if(nevCELabund >0)   print "(A24,ES8.2)"               , "  Ne++++/H+             ",nevCELabund
        if(runonce == 0 .and. nevCELabund >0) iteration_result(1)%Nev_abund_CEL = nevCELabund
if(NeabundCEL > 0) print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," Neon           ",CELicfNe,NeabundCEL,12+log10(NeabundCEL)
        if(runonce == 0 .and. NeabundCEL > 0) iteration_result(1)%Ne_abund_CEL = NeabundCEL
!argon
if(ariiiCELabund >0) print "(A24,ES8.2)"               , "  Ar++/H+               ",ariiiCELabund
        if(runonce == 0 .and. ariiiCELabund >0) iteration_result(1)%Ariii_abund_CEL = ariiiCELabund
if(arivCELabund >0)  print "(A24,ES8.2)"               , "  Ar+++/H+              ",arivCELabund
        if(runonce == 0 .and. arivCELabund >0) iteration_result(1)%Ariv_abund_CEL = arivCELabund
if(arvCELabund >0)   print "(A24,ES8.2)"               , "  Ar++++/H+             ",arvCELabund
        if(runonce == 0 .and. arvCELabund >0) iteration_result(1)%Arv_abund_CEL = arvCELabund
if(ArabundCEL > 0) print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," Argon          ",CELicfAr,ArabundCEL,12+log10(ArabundCEL)
        if(runonce == 0 .and. ArabundCEL > 0) iteration_result(1)%Ar_abund_CEL = ArabundCEL
!sulphur
if(siiCELabund >0) print "(A24,ES8.2)"                , "  S+/H+                 ",siiCELabund
        if(runonce == 0 .AND. siiCELabund >0) iteration_result(1)%Sii_abund_CEL = siiCELabund
if(siiiCELabund >0) print "(A24,ES8.2)"               , "  S++/H+                ",siiiCELabund
        if(runonce == 0 .AND. siiiCELabund >0) iteration_result(1)%Siii_abund_CEL = siiiCELabund
if(SabundCEL > 0)  print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," Sulphur        ",CELicfS,SabundCEL,12+log10(SabundCEL)
        if(runonce == 0 .AND. SabundCEL > 0) iteration_result(1)%S_abund_CEL = SabundCEL
!chlorine
if(cliiiCELabund >0) print "(A24,ES8.2)"               , "  Cl++/H+               ",cliiiCELabund
        if(runonce == 0 .AND. cliiiCELabund >0) iteration_result(1)%Cliii_abund_CEL = cliiiCELabund
if(ClabundCEL > 0)  print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," Chlorine       ",CELicfCl,ClabundCEL,12+log10(ClabundCEL)
        if(runonce == 0 .AND. ClabundCEL > 0) iteration_result(1)%Cl_abund_CEL = ClabundCEL


if(OabundCEL > 0 .and. NabundCEL > 0)  print*, " "
if(OabundCEL > 0 .and. NabundCEL > 0)  print*, " "
if(OabundCEL > 0 .and. NabundCEL > 0)  print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," N/O            ", log10(NabundCEL/OabundCEL)
if(NCabundCEL > 0 .and. NOabundCEL > 0) print*, " "
if(NCabundCEL > 0 .and. NOabundCEL > 0) print "(A15,F5.2,4X,ES8.2,2X,F5.2)"," nC/nO            ", log10(NCabundCEL/NOabundCEL)


print *,""
print *,"ORLs"
print *,""
print *,"Element     ICF     X/H"
print *,"-------     ---     ---"
if(Hetotabund > 0) print "(A12,F5.2,4X,ES8.2,2X,F5.2)"," Helium      ",1.0,Hetotabund,12+log10(Hetotabund)
        if(runonce == 0 .AND. Hetotabund > 0) iteration_result(1)%He_abund_ORL = Hetotabund
if(CabundRL > 0) print "(A12,F5.2,4X,ES8.2,2X,F5.2)"," Carbon      ",RLicfC,CabundRL,12+log10(CabundRL)
        if(runonce == 0 .AND. CabundRL > 0) iteration_result(1)%C_abund_ORL = CabundRL
if(NabundRL > 0) print "(A12,F5.2,4X,ES8.2,2X,F5.2)"," Nitrogen    ",RLicfN,NabundRL,12+log10(NabundRL)
        if(runonce == 0 .AND. NabundRL > 0) iteration_result(1)%N_abund_ORL = NabundRL
if(OabundRL > 0) print "(A12,F5.2,4X,ES8.2,2X,F5.2)"," Oxygen      ",RLicfO,OabundRL,12+log10(OabundRL)
        if(runonce == 0 .AND. OabundRL > 0) iteration_result(1)%O_abund_ORL = OabundRL
if(NeabundRL > 0) print "(A12,F5.2,4X,ES8.2,2X,F5.2)"," Neon        ",RLicfNe,NeabundRL,12+log10(NeabundRL)
        if(runonce == 0 .AND. NeabundRL > 0) iteration_result(1)%Ne_abund_ORL = NeabundRL


!Strong line methods

        print *,""
        print *,"O/H (strong line methods)"
        print *,"-------------------"
        print *,"Calibration         Reference          O/H"

x23temp1 = ILs(get_ion("oii3726    ",ILs, Iint))%int_dered
x23temp2 = ILs(get_ion("oii3729    ",ILs, Iint))%int_dered
x23temp3 = ILs(get_ion("oiii4959   ",ILs, Iint))%int_dered
x23temp4 = ILs(get_ion("oiii5007   ",ILs, Iint))%int_dered

if (ILs(get_ion("oii3728b   ",ILs, Iint))%int_dered .gt. 0 .and. x23temp3 .gt. 0 .and. x23temp4 .gt. 0) then ! OII blended
        X23 = log10(ILs(get_ion("oii3728b   ",ILs, Iint))%int_dered/(x23temp3 + x23temp4))
elseif (x23temp1 .gt. 0 .and. x23temp2 .gt. 0 .and. x23temp3 .gt. 0 .and. x23temp4 .gt. 0) then
        X23 = log10((x23temp1+x23temp2)/(x23temp3+x23temp4))
else
        X23 = 0.
endif

if (X23 .gt. 0) then
  O_R23upper = 9.50 - (1.4 * X23)
  O_R23lower = 6.53 + (1.45 * X23)
  print "(1X,A37,2X,F5.2)","R23 (upper branch)  Pilyugin 2000    ",O_R23upper
  print "(1X,A37,2X,F5.2)","R23 (lower branch)  Pilyugin 2000    ",O_R23lower
endif

ion_no1 = get_ion("nii6584    ",ILs, Iint)
if (ILs(ion_no1)%int_dered .gt. 0 .and. H_BS(1)%int_dered .gt. 0) then
  N2 = ILs(ion_no1)%int_dered / H_BS(1)%int_dered
  O_N2 = 8.90 + (0.57 * N2)
  print "(1X,A37,2X,F5.2)","N2                  Pet. + Pag. 2004 ",O_N2
endif

ion_no2 = get_ion("oiii5007   ",ILs, Iint)
if (ILS(ion_no1)%int_dered .gt. 0 .and. ILs(ion_no2)%int_dered .gt. 0) then
  O3N2 = log10((ILS(ion_no2)%int_dered*H_BS(1)%int_dered)/(ILS(ion_no1)%int_dered * H_BS(2)%int_dered))
  O_O3N2 = 8.73 - (0.32*O3N2)
  print "(1X,A37,2X,F5.2)","O3N2                Pet. + Pag. 2004 ",O_O3N2
endif

ion_no1 = get_ion("ariii7135  ",ILs, Iint)
ion_no2 = get_ion("oiii5007   ",ILs, Iint)
if (ILs(ion_no1)%int_dered .gt. 0 .and. ILs(ion_no2)%int_dered .gt. 0) then
  Ar3O3 = ILs(ion_no1)%int_dered / ILs(ion_no2)%int_dered
  O_Ar3O3 = 8.91 + (0.34*Ar3O3) + (0.27*Ar3O3**2) + (0.2*Ar3O3**3)
  print "(1X,A37,2X,F5.2)","Ar3O3               Stasinska 2006   ",O_Ar3O3
endif

ion_no1 = get_ion("siii9069   ",ILs, Iint)
if (ILs(ion_no1)%int_dered .gt. 0 .and. ILs(ion_no2)%int_dered .gt. 0) then
  S3O3 = ILs(ion_no1)%int_dered / ILs(ion_no2)%int_dered
  O_S3O3 = 9.37 + (2.03*S3O3) + (1.26*S3O3**2) + (0.32*S3O3**3)
  print "(1X,A37,2X,F5.2)","S3O3                Stasinska 2006   ",O_S3O3
endif

!abundance discrepancy factors

print *,""
print *,"Abundance Discrepancy Factors"
print *,"============================="
print *,""

  if (oiiiCELabund .gt. 0) then
    adfO2plus = oiiRLabund/oiiiCELabund
  else
    adfO2plus = 0.0
  endif

  if (oabundCEL .gt. 0) then
    adfO = OabundRL/OabundCEL
  else
    adfO = 0.0
  endif


  if (ciiiCELabund .gt. 0) then
    adfC2plus = ciiRLabund/ciiiCELabund
  else
    adfC2plus = 0.0
  endif

  if (CabundCEL .gt. 0) then
    adfC = CabundRL/CabundCEL
  else
    adfC = 0.0
  endif


  if (NiiiCELabund .gt. 0) then
    adfN2plus = NiiRLabund/NiiiCELabund
  else
    adfN2plus = 0.0
  endif

  if (NabundCEL .gt. 0) then
    adfN = NabundRL/NabundCEL
  else
    adfN = 0.0
  endif


  if (NeiiiCELabund .gt. 0) then
    adfNe2plus = NeiiRLabund/NeiiiCELabund
  else
    adfNe2plus = 0.0
  endif

  if (NeabundCEL .gt. 0) then
    adfNe = NeabundRL/NeabundCEL
  else
    adfNe = 0.0
  endif

if(adfo2plus >0) print "(A12,F7.2)","adf (O2+) = ", adfo2plus
if(adfO>0) print "(A12,F7.2)","adf (O)   = ", adfO
if(adfn2plus>0) print *,""
if(adfn2plus>0) print "(A12,F7.2)","adf (N2+) = ", adfn2plus
if(adfn>0) print "(A12,F7.2)","adf (N)   = ", adfn
if(adfc2plus>0) print *,""
if(adfc2plus>0) print "(A12,F7.2)","adf (C2+) = ", adfc2plus
if(adfc>0) print "(A12,F7.2)","adf (C)   = ", adfc
if(adfne2plus>0) print *,""
if(adfne2plus>0) print "(A12,F7.2)","adf (Ne2+)= ", adfne2plus
if(adfne>0) print "(A12,F7.2)","adf (Ne)  = ", adfne




contains

        SUBROUTINE get_diag(name1, name2, lines, diag)
                TYPE(line), DIMENSION(:), INTENT(IN) :: lines
                CHARACTER*11 :: name1, name2
                INTEGER :: ion_no1, ion_no2
                DOUBLE PRECISION :: diag

                ion_no1 = get_ion(name1, ILs, Iint)
                ion_no2 = get_ion(name2, ILs, Iint)

                if((ILs(ion_no1)%int_dered .gt. 0) .AND. (ILs(ion_no2)%int_dered .gt. 0))then
                        diag = DBLE(ILs(ion_no1)%int_dered) / DBLE(ILs(ion_no2)%int_dered)
                else
                        diag = 0.0
                endif

        END SUBROUTINE

        SUBROUTINE get_Tdiag(name1, name2, name3, lines, factor1, factor2, ratio)
                                                        !3.47,   1.403   SIII
                TYPE(line), DIMENSION(:), INTENT(IN) :: lines
                CHARACTER*11 :: name1, name2, name3
                INTEGER :: ion_no1, ion_no2, ion_no3
                DOUBLE PRECISION :: diag, factor1, factor2, ratio, ratio2


                ion_no1 = get_ion(name1, ILs, Iint)
                ion_no2 = get_ion(name2, ILs, Iint)
                ion_no3 = get_ion(name3, ILs, Iint)

                if(((ILs(ion_no1)%int_dered .gt. 0) .AND. (ILs(ion_no2)%int_dered .gt. 0)) .and. (ILs(ion_no3)%int_dered .gt. 0 ))then

                        ratio = (ILs(ion_no1)%int_dered + ILs(ion_no2)%int_dered) / ILs(ion_no3)%int_dered

                        if(name1 == "siii9069   ")then
                                ratio2 = (ILs(ion_no1)%int_dered / ILs(ion_no2)%int_dered)
                                !print*, ratio2
                                if(ratio2 > (factor2-1)*0.95 .and. ratio2 < (factor2-1)*1.05)then
                                        !PRINT*, ratio2, " ", factor2-1, " 1 ", name1
                                        ratio = (ILs(ion_no1)%int_dered + ILs(ion_no2)%int_dered) / ILs(ion_no3)%int_dered
                                else if(ratio2 < (factor2-1)*0.95)then
                                        !PRINT*, ratio2, " ", factor2-1, " 2 ", name1
                                        ratio = (factor2 * ILs(ion_no2)%int_dered) / ILs(ion_no3)%int_dered
                                        !PRINT*, (factor2 * ILs(ion_no2)%int_dered), " ", (ILs(ion_no1)%int_dered + ILs(ion_no2)%int_dered)
                                else if(ratio2 > (factor2-1)*1.05)then
                                        !PRINT*, ratio2, " ", factor2-1, " 3 ", name1
                                        ratio = (factor1 * ILs(ion_no1)%int_dered) / ILs(ion_no3)%int_dered
                                else
                                        ratio = 0.0
                                end if
                        end if

                elseif(((ILs(ion_no1)%int_dered .gt. 0) .AND. (ILs(ion_no2)%int_dered .eq. 0)) .and. (ILs(ion_no3)%int_dered .gt. 0 ))then
                        ratio = (ILs(ion_no1)%int_dered * factor1) / ILs(ion_no3)%int_dered
                elseif(((ILs(ion_no1)%int_dered .eq. 0) .AND. (ILs(ion_no2)%int_dered .gt. 0)) .and. (ILs(ion_no3)%int_dered .gt. 0 ))then
                        ratio = (ILs(ion_no2)%int_dered * factor2) / ILs(ion_no3)%int_dered
                else
                        ratio = 0.0
                endif


        END SUBROUTINE



end subroutine abundances
