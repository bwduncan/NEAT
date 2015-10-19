! conversion of MIDAS script Roii.prg, written by XWL, to F90
! RW May 2009

      module mod_recombination_lines

      implicit none
      private :: dp
      integer, parameter :: dp = kind(1.d0)

      TYPE oiiRL
            CHARACTER(len=1) :: Hyb
            CHARACTER(len=1) :: n_E1
            CHARACTER(len=1) :: n_E1GA
            CHARACTER(len=1) :: n_E2
            CHARACTER(len=1) :: n_E2GA
            CHARACTER(len=1) :: n_g1
            CHARACTER(len=1) :: n_g2
            CHARACTER(len=1) :: Rem1
            CHARACTER(len=1) :: Rem2
            CHARACTER(len=1) :: Rem3
            CHARACTER(len=1) :: Rem4
            CHARACTER(len=3) :: q_gf1
            CHARACTER(len=3) :: q_gf2
            CHARACTER(len=7) :: Mult
            CHARACTER(len=9) :: Term1
            CHARACTER(len=9) :: Term2
            INTEGER :: g1
            INTEGER :: g2
            INTEGER :: ION
            real(kind=dp) :: Wave
            real(kind=dp) :: E1
            real(kind=dp) :: E2
            real(kind=dp) :: Em
            real(kind=dp) :: Int
            real(kind=dp) :: Br_A
            real(kind=dp) :: Br_B
            real(kind=dp) :: Br_C
            real(kind=dp) :: gf1
            real(kind=dp) :: gf2
            real(kind=dp) :: Obs
            real(kind=dp) :: abundance
      END TYPE

      TYPE(oiiRL), DIMENSION(:), allocatable :: oiiRLs

      real(kind=dp), dimension(36,9), target :: oii_coefficients
      real(kind=dp), dimension(:), pointer :: A_4f, A_3d4F, A_3d4D, B_3d4D, C_3d4D, A_3d2F, B_3d2F, C_3d2F, A_3d2D, C_3d2D, A_3d2P, C_3d2P, A_3p4D, B_3p4D, A_3p4P, B_3p4P, A_3p4S, B_3p4S, A_3p2D, C_3p2D, A_3p2P, C_3p2P, A_3p2S, C_3p2S, A_4f_low, A_3d4F_low, B_3d4D_low, A_3d2F_low, A_3d2D_low, A_3d2P_low, A_3p4D_low, A_3p4P_low, A_3p4S_low, A_3p2D_low, A_3p2P_low, A_3p2S_low

      TYPE niiRL
            CHARACTER(len=1) :: Hyb
            CHARACTER(len=1) :: n_E1
            CHARACTER(len=1) :: n_E1GA
            CHARACTER(len=1) :: n_E2
            CHARACTER(len=1) :: n_E2GA
            CHARACTER(len=1) :: n_g1
            CHARACTER(len=1) :: n_g2
            CHARACTER(len=1) :: Rem1
            CHARACTER(len=1) :: Rem2
            CHARACTER(len=1) :: Rem3
            CHARACTER(len=1) :: Rem4
            CHARACTER(len=3) :: q_gf1
            CHARACTER(len=3) :: q_gf2
            CHARACTER(len=7) :: Mult
            CHARACTER(len=9) :: Term1
            CHARACTER(len=9) :: Term2
            INTEGER :: g1
            INTEGER :: g2
            INTEGER :: ION
            real(kind=dp) :: Wave
            real(kind=dp) :: E1
            real(kind=dp) :: E2
            real(kind=dp) :: Em
            real(kind=dp) :: Int
            real(kind=dp) :: Br_LS
            real(kind=dp) :: gf1
            real(kind=dp) :: gf2
            real(kind=dp) :: Obs
            real(kind=dp) :: abundance
      END TYPE

      TYPE(niiRL), DIMENSION(:),allocatable :: niiRLs

      TYPE ciiRL
            real(kind=dp) :: Wave
            real(kind=dp) :: a
            real(kind=dp) :: b
            real(kind=dp) :: c
            real(kind=dp) :: d
            real(kind=dp) :: f
            real(kind=dp) :: aeff
            real(kind=dp) :: Int
            real(kind=dp) :: Obs
            real(kind=dp) :: abundance
      END TYPE

      TYPE(ciiRL), DIMENSION(:),allocatable :: ciiRLs

      TYPE neiiRL
            real(kind=dp) :: Wave
            real(kind=dp) :: a
            real(kind=dp) :: b
            real(kind=dp) :: c
            real(kind=dp) :: d
            real(kind=dp) :: f
            real(kind=dp) :: Br
            real(kind=dp) :: aeff
            real(kind=dp) :: Int
            real(kind=dp) :: Obs
            real(kind=dp) :: abundance
      END TYPE

      TYPE(neiiRL), DIMENSION(:),allocatable :: neiiRLs

      TYPE xiiiRL
            CHARACTER(len=3) :: Ion
            real(kind=dp) :: Wave
            real(kind=dp) :: a
            real(kind=dp) :: b
            real(kind=dp) :: c
            real(kind=dp) :: d
            real(kind=dp) :: Br
            real(kind=dp) :: aeff
            real(kind=dp) :: Int
            real(kind=dp) :: Obs
            real(kind=dp) :: abundance
      END TYPE

      TYPE(xiiiRL), DIMENSION(:),allocatable :: xiiiRLs

      contains

      subroutine read_orl_data

        IMPLICIT NONE
        integer :: i, nlines
        ! read in OII data

            301 FORMAT (I5, 1X, F9.4, 1X, A1, A1, A1, A1, A1, F7.4,     &
     & 1X, A3, 1X, F7.4, 1X, A3, 1X, A7, 3X, F11.4, A1, A1, 1X, I2, &
     &1X, A1, 1X, A9, 1X, F13.4, 1X, A1, A1, 1X, I2, 1X, A1, 1X, A9, 1X,&
     & F7.4, 1X, F7.4, 1X, F7.4)!, 1X, E10.4, 1X, E10.4, 1X)
            OPEN(201, file="Atomic-data/Roii.dat", status='old')
            read(201,*) nlines
            allocate(oiiRLs(nlines))
            oiiRLs%Int = 0.d0
            oiiRLs%Obs=0.d0
            oiiRLs%abundance=0.d0
            DO i = 1,nlines
            READ(201,301) oiiRLs(i)%ION, oiiRLs(i)%Wave, oiiRLs(i)%Hyb, &
     &oiiRLs(i)%Rem1, oiiRLs(i)%Rem2, oiiRLs(i)%Rem3, oiiRLs(i)%Rem4,   &
     &oiiRLs(i)%gf1, oiiRLs(i)%q_gf1, oiiRLs(i)%gf2, oiiRLs(i)%q_gf2,   &
     &oiiRLs(i)%Mult, oiiRLs(i)%E1, oiiRLs(i)%n_E1, oiiRLs(i)%n_E1GA,   &
     &oiiRLs(i)%g1, oiiRLs(i)%n_g1, oiiRLs(i)%Term1, oiiRLs(i)%E2,      &
     &oiiRLs(i)%n_E2, oiiRLs(i)%n_E2GA, oiiRLs(i)%g2, oiiRLs(i)%n_g2,   &
     &oiiRLs(i)%Term2, oiiRLs(i)%Br_A, oiiRLs(i)%Br_B, oiiRLs(i)%Br_C
            END DO
      CLOSE(201)

     ! coefficients from LSBC 1995, S94
     ! array consists of coefficients a2, a4, a5, a6, b, c and d, plus calculated values a and aeff
     ! an is the coefficient a at log(ne)=n. this will be interpolated and stored in variable a.
     ! the interpolated a is then used with the other coefficients to calculate aeff
     ! replace with reading from file at some point

      oii_coefficients(1,:) = (/0.236d0,0.232d0,0.228d0,0.222d0,-0.92009d0,0.15526d0,0.03442d0,0.d0,0.d0/)
      oii_coefficients(2,:) = (/0.876d0,0.876d0,0.877d0,0.880d0,-0.73465d0,0.13689d0,0.06220d0,0.d0,0.d0/)
!      oii_coefficients(3,:) = (/0.727d0,0.726d0,0.725d0,0.726d0,-0.73465d0,0.13689d0,0.06220d0,0.d0,0.d0/)
      oii_coefficients(4,:) = (/0.747d0,0.745d0,0.744d0,0.745d0,-0.74621d0,0.15710d0,0.07059d0,0.d0,0.d0/)
!      oii_coefficients(5,:) = (/0.769d0,0.767d0,0.766d0,0.766d0,-0.74621d0,0.15710d0,0.07059d0,0.d0,0.d0/)
      oii_coefficients(6,:) = (/0.727d0,0.726d0,0.725d0,0.726d0,-0.74621d0,0.15710d0,0.07059d0,0.d0,0.d0/)
!      oii_coefficients(7,:) = (/0.747d0,0.745d0,0.744d0,0.745d0,-0.74621d0,0.15710d0,0.07059d0,0.d0,0.d0/)
!      oii_coefficients(8,:) = (/0.769d0,0.767d0,0.766d0,0.766d0,-0.74621d0,0.15710d0,0.07059d0,0.d0,0.d0/)
      oii_coefficients(9,:) = (/0.603d0,0.601d0,0.600d0,0.599d0,-0.79533d0,0.15314d0,0.05322d0,0.d0,0.d0/)
!      oii_coefficients(10,:) = (/0.620d0,0.618d0,0.616d0,0.615d0,-0.79533d0,0.15314d0,0.05322d0,0.d0,0.d0/)
      oii_coefficients(11,:) = (/0.526d0,0.524d0,0.523d0,0.524d0,-0.78448d0,0.13681d0,0.05608d0,0.d0,0.d0/)
!      oii_coefficients(1,:) = (/0.538d0,0.536d0,0.535d0,0.536d0,-0.78448d0,0.13681d0,0.05608d0,0.d0,0.d0/)
      oii_coefficients(13,:) = (/34.7d0,34.9d0,35.1d0,35.0d0,-0.749d0,0.023d0,0.074d0,0.d0,0.d0/)
      oii_coefficients(14,:) = (/36.0d0,36.2d0,36.4d0,36.3d0,-0.736d0,0.033d0,0.077d0,0.d0,0.d0/)
      oii_coefficients(15,:) = (/10.4d0,10.4d0,10.5d0,10.4d0,-0.721d0,0.073d0,0.072d0,0.d0,0.d0/)
      oii_coefficients(16,:) = (/14.6d0,14.6d0,14.7d0,14.6d0,-0.732d0,0.081d0,0.066d0,0.d0,0.d0/)
      oii_coefficients(17,:) = (/0.90d0,0.90d0,0.90d0,1.00d0,-0.485d0,-0.047d0,0.140d0,0.d0,0.d0/)
      oii_coefficients(18,:) = (/4.80d0,4.90d0,4.90d0,4.90d0,-0.730d0,-0.003d0,0.057d0,0.d0,0.d0/)
      oii_coefficients(19,:) = (/2.40d0,2.40d0,2.50d0,2.60d0,-0.550d0,-0.051d0,0.178d0,0.d0,0.d0/)
      oii_coefficients(20,:) = (/14.5d0,14.6d0,14.5d0,14.3d0,-0.736d0,0.068d0,0.066d0,0.d0,0.d0/)
      oii_coefficients(21,:) = (/1.10d0,1.20d0,1.20d0,1.20d0,-0.523d0,-0.044d0,0.173d0,0.d0,0.d0/)
      oii_coefficients(22,:) = (/1.30d0,1.40d0,1.40d0,1.40d0,-0.565d0,-0.042d0,0.158d0,0.d0,0.d0/)
      oii_coefficients(23,:) = (/0.40d0,0.40d0,0.40d0,0.40d0,-0.461d0,-0.083d0,0.287d0,0.d0,0.d0/)
      oii_coefficients(24,:) = (/0.50d0,0.50d0,0.50d0,0.60d0,-0.547d0,-0.074d0,0.244d0,0.d0,0.d0/)

      oii_coefficients(25,:) = (/0.236d0,0.236d0,0.236d0,0.236d0,-1.07552d0,-0.04843d0,0.d0,0.d0,0.d0/)
      oii_coefficients(26,:) = (/0.878d0,0.878d0,0.878d0,0.878d0,-0.86175d0,-0.02470d0,0.d0,0.d0,0.d0/)
      oii_coefficients(27,:) = (/0.747d0,0.747d0,0.747d0,0.747d0,-0.89382d0,-0.02906d0,0.d0,0.d0,0.d0/)
      oii_coefficients(28,:) = (/0.747d0,0.747d0,0.747d0,0.747d0,-0.89382d0,-0.02906d0,0.d0,0.d0,0.d0/)
      oii_coefficients(29,:) = (/0.603d0,0.603d0,0.603d0,0.603d0,-0.94025d0,-0.03467d0,0.d0,0.d0,0.d0/)
      oii_coefficients(30,:) = (/0.526d0,0.526d0,0.526d0,0.526d0,-0.91758d0,-0.03120d0,0.d0,0.d0,0.d0/)
      oii_coefficients(31,:) = (/36.288d0,36.288d0,36.288d0,36.288d0,-0.75421d0,0.02883d0,0.01213d0,0.d0,0.d0/)
      oii_coefficients(32,:) = (/14.656d0,14.656d0,14.656d0,14.656d0,-0.80449d0,0.00018d0,0.00517d0,0.d0,0.d0/)
      oii_coefficients(33,:) = (/4.8340d0,4.8340d0,4.8340d0,4.8340d0,-0.71947d0,0.02544d0,0.00936d0,0.d0,0.d0/)
      oii_coefficients(34,:) = (/2.3616d0,2.3616d0,2.3616d0,2.3616d0,-0.46263d0,0.14697d0,0.03856d0,0.d0,0.d0/)
      oii_coefficients(35,:) = (/1.1198d0,1.1198d0,1.1198d0,1.1198d0,-0.44147d0,0.13837d0,0.03191d0,0.d0,0.d0/)
      oii_coefficients(36,:) = (/0.3922d0,0.3922d0,0.3922d0,0.3922d0,-0.35043d0,0.26366d0,0.06666d0,0.d0,0.d0/)

!define pointers so that we can refer to the coefficients by state as well as processing all coefficients at once

      A_4f => oii_coefficients(1,:)
    A_3d4F => oii_coefficients(2,:)
    A_3d4D => oii_coefficients(3,:)
    B_3d4D => oii_coefficients(4,:)
    C_3d4D => oii_coefficients(5,:)
    A_3d2F => oii_coefficients(6,:)
    B_3d2F => oii_coefficients(7,:)
    C_3d2F => oii_coefficients(8,:)
    A_3d2D => oii_coefficients(9,:)
    C_3d2D => oii_coefficients(10,:)
    A_3d2P => oii_coefficients(11,:)
    C_3d2P => oii_coefficients(12,:)
    A_3p4D => oii_coefficients(13,:)
    B_3p4D => oii_coefficients(14,:)
    A_3p4P => oii_coefficients(15,:)
    B_3p4P => oii_coefficients(16,:)
    A_3p4S => oii_coefficients(17,:)
    B_3p4S => oii_coefficients(18,:)
    A_3p2D => oii_coefficients(19,:)
    C_3p2D => oii_coefficients(20,:)
    A_3p2P => oii_coefficients(21,:)
    C_3p2P => oii_coefficients(22,:)
    A_3p2S => oii_coefficients(23,:)
    C_3p2S => oii_coefficients(24,:)
  A_4f_low => oii_coefficients(25,:)
A_3d4F_low => oii_coefficients(26,:)
B_3d4D_low => oii_coefficients(27,:)
A_3d2F_low => oii_coefficients(28,:)
A_3d2D_low => oii_coefficients(29,:)
A_3d2P_low => oii_coefficients(30,:)
A_3p4D_low => oii_coefficients(31,:)
A_3p4P_low => oii_coefficients(32,:)
A_3p4S_low => oii_coefficients(33,:)
A_3p2D_low => oii_coefficients(34,:)
A_3p2P_low => oii_coefficients(35,:)
A_3p2S_low => oii_coefficients(36,:)

     ! read in NII data

            302 FORMAT (I5, 1X, F9.4, 1X, A1, A1, A1, A1, A1, 1X, F7.4, &
     & 1X, A3, 1X, F7.4, 1X, A3, 1X, A7, 3X, F11.4, A1, A1, 1X, I2, &
     &1X, A1, 1X, A9, 1X, F13.4, 1X, A1, A1, 1X, I2, 1X, A1, 1X, A9, 1X,&
     & F7.4, 1X, F7.4, 1X, F7.4)!, 1X, E10.4, 1X, E10.4, 1X)
            OPEN(201, file="Atomic-data/Rnii.dat", status='old')
            read(201,*) nlines
            allocate(niiRLs(nlines))
            niiRLs%Int = 0.d0
            niiRLs%Obs=0.d0
            niiRLs%abundance=0.d0
            DO i = 1,nlines
            READ(201,302) niiRLs(i)%ION, niiRLs(i)%Wave, niiRLs(i)%Hyb, &
     &niiRLs(i)%Rem1, niiRLs(i)%Rem2, niiRLs(i)%Rem3, niiRLs(i)%Rem4,   &
     &niiRLs(i)%gf1, niiRLs(i)%q_gf1, niiRLs(i)%gf2, niiRLs(i)%q_gf2,   &
     &niiRLs(i)%Mult, niiRLs(i)%E1, niiRLs(i)%n_E1, niiRLs(i)%n_E1GA,   &
     &niiRLs(i)%g1, niiRLs(i)%n_g1, niiRLs(i)%Term1, niiRLs(i)%E2,      &
     &niiRLs(i)%n_E2, niiRLs(i)%n_E2GA, niiRLs(i)%g2, niiRLs(i)%n_g2,   &
     &niiRLs(i)%Term2, niiRLs(i)%Br_LS
            END DO
      CLOSE(201)

! read in CII data

      303 FORMAT (F7.2, 1X, F6.4, 1X, F7.4, 1X, F7.4, 1X, F7.4, 1X, F7.4)
      OPEN(201, file="Atomic-data/Rcii.dat", status='old')
      read(201,*) nlines
      allocate(ciiRLs(nlines))
      ciiRLs%Int = 0.d0
      ciiRLs%Obs=0.d0
      ciiRLs%abundance=0.d0
      DO i = 1,nlines
        READ(201,303) ciiRLs(i)%Wave, ciiRLs(i)%a, ciiRLs(i)%b, &
        & ciiRLs(i)%c, ciiRLs(i)%d, ciiRLs(i)%f
      END DO
      CLOSE(201)

          ! read in NeII data

      304 FORMAT (F7.2, 1X, F6.3, 1X, F6.3, 1X, F6.3, 1X, F6.3, 1X, F7.4, 1X, F6.3)
      OPEN(201, file="Atomic-data/Rneii.dat", status='old')
      read(201,*) nlines
      allocate(neiiRLs(nlines))
      neiiRLs%Int = 0.d0
      neiiRLs%Obs=0.d0
      neiiRLs%abundance=0.d0
      DO i = 1,nlines
        READ(201,304) neiiRLs(i)%Wave, neiiRLs(i)%a, neiiRLs(i)%b, &
        & neiiRLs(i)%c, neiiRLs(i)%d, neiiRLs(i)%f, neiiRLs(i)%Br
      END DO
      CLOSE(201)

        ! read in XIII data

      305 FORMAT (A3,1X,F7.2, 1X, F5.3, 1X, F6.3, 1X, F5.3, 1X, F5.3, 1X, F5.4)
      OPEN(201, file="Atomic-data/Rxiii.dat", status='old')
      read(201,*) nlines
      allocate(xiiiRLs(nlines))
      xiiiRLs%Int = 0.d0
      xiiiRLs%Obs=0.d0
      xiiiRLs%abundance=0.d0
      DO i = 1,nlines
        READ(201,305) xiiiRLs(i)%ion, xiiiRLs(i)%Wave, xiiiRLs(i)%a, &
        & xiiiRLs(i)%b, xiiiRLs(i)%c, xiiiRLs(i)%d, xiiiRLs(i)%Br
      END DO
      CLOSE(201)

      end subroutine

      subroutine oii_rec_lines(te,ne,abund,oiiRLs)

      IMPLICIT NONE
      real(kind=dp) :: aeff, aeff_hb, Em_Hb, Te, Ne, abund, tered

      TYPE(oiiRL), DIMENSION(:) :: oiiRLs

      call get_aeff_hb(te,ne, aeff_hb, em_hb)

! interpolate the a values

      if (log10(ne) .le. 2) then
        oii_coefficients(:,8)= oii_coefficients(:,1)
      elseif (log10(ne) .gt. 2 .and. log10(ne) .le. 4) then
        oii_coefficients(:,8)= oii_coefficients(:,1) + (oii_coefficients(:,2) - oii_coefficients(:,1)) / 2. * (log10(ne) - 2.)
      elseif (log10(ne) .gt. 4 .and. log10(ne) .le. 5) then
        oii_coefficients(:,8)= oii_coefficients(:,2) + (oii_coefficients(:,3) - oii_coefficients(:,2)) * (log10(ne) - 2.)
      elseif (log10(ne) .gt. 6 .and. log10(ne) .le. 6) then
        oii_coefficients(:,8)= oii_coefficients(:,3) + (oii_coefficients(:,4) - oii_coefficients(:,3)) * (log10(ne) - 2.)
      else
        oii_coefficients(:,8)= oii_coefficients(:,4)
      endif

! calculate the aeffs.  coefficients 

      tered=te/10000.
      oii_coefficients(1:24,9)=1.e-14 * (oii_coefficients(1:24,8) * tered**oii_coefficients(1:24,5) * (1. + oii_coefficients(1:24,6) * (1. - tered) + oii_coefficients(1:24,7) * (1. - tered) ** 2))
      oii_coefficients(25:36,9)=1.e-14 * oii_coefficients(25:36,8) * tered**(oii_coefficients(25:36,5) + oii_coefficients(25:36,6)*log(tered) + oii_coefficients(25:36,7)* log(tered) ** 2)

! 4f-3d transitions

      if (tered .gt. 0.5) then
        aeff=A_4f(9)
      else
        aeff=A_4f_low(9)
      endif

      where (oiiRLs%Term1(4:5) .eq. "3d" .and. oiiRLs%Term2(3:4) .eq. "4f")
        oiiRLs%Em = aeff * 1.98648E-08 /oiiRLs%Wave * &
        & oiiRLs%g2 * oiiRLs%Br_B
        oiiRLs%Int = 100. * oiiRLs%Em / Em_hb * abund
      endwhere

! 3d-3p ^4F transitions (Case A=B=C for a,b,c,d; Br diff. slightly, adopt Case B)

      if (tered .gt. 0.5) then
        aeff=A_3d4F(9)
      else
        aeff=A_3d4F_low(9)
      endif

      where (oiiRLs%Mult .eq. " V10       " .or. oiiRLs%Mult .eq. " V18       ")
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_B
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere
!
! 3d-3p ^4D, ^4P transitions. case B assumed

      if (tered .gt. 0.5) then
        aeff=B_3d4D(9)
      else
        aeff=B_3d4D_low(9)
      endif

      where (oiiRLs%Term1(4:5) .eq. "3p" .and. (oiiRLs%Term2 .eq. "  3d  4D " .or. oiiRLs%Term2 .eq. "  3d  4P "))
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_B
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere
!
! 3d-3p ^2F transitions. case A

      if (tered .gt. 0.5) then
        aeff=A_3d2F(9)
      else
        aeff=A_3d2F_low(9)
      endif

      where (oiiRLs%Term1(4:5) .eq. "3p" .and. oiiRLs%Term2 .eq. "  3d  2F   ")
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_A
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere
!
! 3d-3p ^2D transitions. case A

      if (tered .gt. 0.5) then
        aeff=A_3d2D(9)
      else
        aeff=A_3d2D_low(9)
      endif

      where (oiiRLs%Term1(4:5) .eq. "3d" .and. oiiRLs%Term2 .eq. "  3d  2D   ")
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_A
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere
!
! 3d-3p ^2P transitions. case A

      if (tered .gt. 0.5) then
        aeff=A_3d2P(9)
      else
        aeff=A_3d2P_low(9)
      endif

      where (oiiRLs%Term1(4:5) .eq. "3p" .and. oiiRLs%Term2 .eq. "  3d  2P   ")
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_A
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere
!
! 3p-3s ^4D - ^4P transitions. case B

      if (tered .gt. 0.5) then
        aeff=B_3p4D(9)
      else
        aeff=A_3p4D_low(9)
      endif

      where (oiiRLs%Mult .eq. " V1        ")
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_B
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere
!
! 3p-3s ^4P - ^4P transitions. case B

      if (tered .gt. 0.5) then
        aeff=B_3p4P(9)
      else
        aeff=A_3p4P_low(9)
      endif
!
      where (oiiRLs%Mult .eq. " V2        ")
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_B
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere
!
! 3p-3s ^4S - ^4P transitions. case B

      if (tered .gt. 0.5) then
        aeff=B_3p4S(9)
      else
        aeff=A_3p4S_low(9)
      endif
!
      where (oiiRLs%Mult .eq. " V3        ")
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_B
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere
!
! 3p-3s ^2D - ^2P transitions. case A

      if (tered .gt. 0.5) then
        aeff=A_3p2D(9)
      else
        aeff=A_3p2D_low(9)
      endif
!
      where (oiiRLs%Mult .eq. " V5        ")
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_A
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere
!
! 3p-3s ^2P - ^2P transitions. case A

      if (tered .gt. 0.5) then
        aeff=A_3p2P(9)
      else
        aeff=A_3p2P_low(9)
      endif
!
      where (oiiRLs%Mult .eq. " V6        ")
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_A
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere
!
! 3p-3s ^2S - ^2P transitions. case A

      if (tered .gt. 0.5) then
        aeff=A_3p2S(9)
      else
        aeff=A_3p2S_low(9)
      endif
!
      where (oiiRLs%Mult .eq. " V4        ")
        oiiRLs%Em = aeff*1.98648E-08 / oiiRLs%Wave*&
      & oiiRLs%g2*oiiRLs%Br_A
        oiiRLs%Int = 100.*oiiRLs%Em / Em_hb*abund
      endwhere

      end subroutine oii_rec_lines

      subroutine nii_rec_lines(te, ne, abund, niiRLs)

      IMPLICIT NONE
      real(kind=dp) :: aeff, aeff_hb, Em_Hb, Te, Ne, abund, Br_term, z, tered
      real(kind=dp) :: a, b, c, d

      TYPE(niiRL), DIMENSION(:) :: niiRLs

      call get_aeff_hb(te,ne, aeff_hb, em_hb)

      tered = te/10000.

!     2s2.2p.(2P*).3s - 2s2.2p.(2P*).3p E1 3P* - 3D  M03  transitions
!     case B
      a = -12.7289
      b = -0.689816
      c = 0.022005
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V3         ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!      2s2.2p.(2P*).3s - 2s2.2p.(2P*).3p 3P* - 3S     M04 transitions
!      case B
      a = -13.8161
      b = -0.778606
      c = -0.028944
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V4         ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3s - 2s2.2p.(2P*).3p 3P* - 3P     M05 transitions
!      case B
      a = -13.0765
      b = -0.734594
      c = -0.0251909
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)

      where (niiRLs%Mult .eq. "V5         ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3s - 2s2.2p.(2P*).3p 1P* - 1P     M08 transitions
!      case A
      a = -14.1211
      b = -0.608107
      c = 0.0362301
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V8         ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3s - 2s2.2p.(2P*).3p 1P* - 1D     M12 transitions
!      case A
      a = -13.7473
      b = -0.509595
      c = 0.0255685
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V12        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3s - 2s2.2p.(2P*).3p 1P* - 1S     M13 transitions
!      case A
      a = -14.3753
      b = -0.515547
      c = 0.0100966
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V13        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).3d 1P - 1D*     M15 transitions
!      case A
      a = -14.3932
      b = -0.887946
      c = -0.0525855
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V15        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).3d 1P - 1P*     M17 transitions
!      case A
      a = -15.0052
      b = -0.89811
      c = -0.0581789
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V17        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).3d 3D - 3F*     M19 transitions
!      case B
      a = -12.6183
      b = -0.840727
      c = -0.0229685
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V19        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).3d 3D - 3D*     M20 transitions
!      case B
      a = -13.3184
      b = -0.884034
      c = -0.0512093
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V20        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).3d 3D - 3P*     M21 transitions
!      case B
      a = -14.5113
      b = -0.87792
      c = -0.0552785
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V21        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).4s 3D - 3P*     M22 transitions
!      case B
      a = -14.1305
      b = -0.487037
      c = 0.0354135
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V22        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).3d 3S - 3P*     M24 transitions
!      case B
      a = -13.3527
      b = -0.878224
      c = -0.0557112
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V24        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).4s 3S - 3P*     M26 transitions
!      case B
      a = -14.9628
      b = -0.486746
      c = 0.0358261
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V26        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).3d 3P - 3D*     M28 transitions
!      case B
      a = -13.0871
      b = -0.883624
      c = -0.0506882
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V28        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).3d 3P - 3P*     M29 transitions
!      case B
      a = -13.5581
      b = -0.878488
      c = -0.0557583
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V29        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).4s 3P - 3P*     M30 transitions
!      case B
      a = -14.3521
      b = -0.487527
      c = 0.0355516
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V30        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3p - 2s2.2p.(2P*).3d 1D - 1F*     M31 transitions
!      case A
      a = -15.0026
      b = -0.923093
      c = -0.0588371
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V31        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3d - 2s2.2p.(2P*).4p 3F* - 3D     M36 transitions
!      case B
      a = -13.8636
      b = -0.569144
      c = 0.0068655
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult .eq. "V36        ")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3d - 2s2.2p.(2P*<3/2>).4f 3F* - 3G M39 transitions
!      case B
      a = -13.035
      b = -1.12035
      c = -0.10642
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult(1:3) .eq. "V39")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       2s2.2p.(2P*).3d - 2s2.2p.(2P*<3/2>).4f 1F* - 1G M58 transitions
!      case A
      a = -13.5484
      b = -1.11909
      c = -0.105123
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult(1:3) .eq. "V58")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       3d 3D* - 4f 3F 4242 M48 transitions
!      case B
      a = -13.2548
      b = -1.12902
      c = -0.110368
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult(1:3) .eq. "V48")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       3d 3P* - 4f 3D 4435 M55 transitions
!      case B
      a = -13.5656
      b = -1.11989
      c = -0.105818
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult(1:3) .eq. "V55")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       3d 1D* - 4f 1F 4176 M43 (RMT M42) transitions
!      case A
      a = -13.7426
      b = -1.13351
      c = -0.111146
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult(1:3) .eq. "V43")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       3d 1P* - 4f 1D 4677 M61 (RMT M62) transitions
!      case A
      a = -13.7373
      b = -1.12695
      c = -0.108158
!
      aeff = 10. ** (a + b * log10(tered) + c * log10(tered) ** 2)
      where (niiRLs%Mult(1:3) .eq. "V61")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       3d 3F* - 4f 1G 4026 M39b transitions
!      case A (PPB):
      a = 0.108
      b = -0.754
      c = 2.587
      d = 0.719
      z = 2.
      Br_term = 0.350
!
      aeff = 1.e-13 * z * a  * (tered/z**2) ** (b)
      aeff = aeff / (1. + c * (tered/z**2) ** (d)) * Br_term
      where (niiRLs%Mult(1:4) .eq. "V39b")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere
!
!       3d 1F* - 4f 3G 4552 M58a transitions
!      case A (PPB):
      a = 0.326
      b = -0.754
      c = 2.587
      d = 0.719
      z = 2.
      Br_term = 0.074
!
      aeff = 1.e-13 * z * a  * (tered/z**2) ** (b)
      aeff = aeff / (1. + c * (tered/z**2) ** (d)) * Br_term
      where (niiRLs%Mult(1:4) .eq. "V58a")
        niiRLs%Em = aeff * 1.98648E-08 / niiRLs%Wave * niiRLs%Br_LS
        niiRLs%Int = 100 * niiRLs%Em / Em_Hb * abund
      endwhere

      end subroutine nii_rec_lines

      subroutine cii_rec_lines(te, ne, abund, ciiRLs)

      IMPLICIT NONE
      real(kind=dp) :: aeff_Hb, Em_Hb, Te, Ne, abund, tered

      TYPE(ciiRL), DIMENSION(:) :: ciiRLs

      call get_aeff_hb(te,ne, aeff_hb, em_hb)

      tered = te/10000

      ciiRLs%aeff = 1e-14 * (ciiRLs%a*(tered**ciiRLs%f)) * (1 &
      &+ (ciiRLs%b*(1-tered)) &
      &+ (ciiRLs%c * ((1-tered)**2) ) &
      &+ (ciiRLs%d * ((1-tered)**3) ) &
      &)
      ciiRLs%Int = 100 * (ciiRLs%aeff/aeff_hb) * (4861.33/ciiRLs%Wave) * abund

      end subroutine cii_rec_lines

      subroutine neii_rec_lines(te, ne, abund, neiiRLs)

      IMPLICIT NONE
      real(kind=dp) :: aeff_Hb, Em_Hb, Te, Ne, abund, tered

      TYPE(neiiRL), DIMENSION(:) :: neiiRLs

      call get_aeff_hb(te,ne, aeff_hb, em_hb)

      tered = te/10000

      neiiRLs%aeff = neiiRLs%Br * 1e-14 * &
      &(neiiRLs%a*(tered**neiiRLs%f)) * (1 &
      &+ (neiiRLs%b*(1-tered)) &
      &+ (neiiRLs%c * ((1-tered)**2) ) &
      &+ (neiiRLs%d * ((1-tered)**3) ) &
      &)
      neiiRLs%Int = 100 * (neiiRLs%aeff/aeff_hb) * (4861.33/neiiRLs%Wave) * abund

      end subroutine neii_rec_lines

      subroutine xiii_rec_lines(te, ne, abund, xiiiRLs)

      IMPLICIT NONE
      real(kind=dp) :: aeff_Hb, Em_Hb, Te, Ne, abund, tered

      TYPE(xiiiRL), DIMENSION(:) :: xiiiRLs

      call get_aeff_hb(te,ne, aeff_hb, em_hb)

      tered = te/90000. !ionic charge=3 so divide by 9

      xiiiRLs%aeff = xiiiRLs%Br * 1e-13 * 3 * &
      & (xiiiRLs%a*(tered**xiiiRLs%b)) / &
      & (1 + (xiiiRLs%c * (tered**xiiiRLs%d)))
      xiiiRLs%Int = 100 * (xiiiRLs%aeff/aeff_hb) * (4861.33/xiiiRLs%Wave) * abund

      end subroutine xiii_rec_lines

      subroutine get_aeff_hb(te, ne, aeff_hb, em_hb)
      IMPLICIT NONE
      real(kind=dp) :: Te, Ne, AE2, AE3, AE4, AE5, AE6, AE7, AE8, aeff_hb, Em_Hb, logem

      AE2 = -9.06524E+00 -2.69954E+00 * log10(te) + 8.80123E-01 * &
      &log10(te) ** 2 -1.57946E-01 * log10(te) ** 3 + &
      &9.25920E-03 * log10(te) ** 4
      AE3 = -8.13757E+00 -3.57392E+00 * log10(te) + 1.19331E+00 * &
      &log10(te) ** 2 -2.08362E-01 * log10(te) ** 3 + &
      &1.23303E-02 * log10(te) ** 4
      AE4 = -6.87230E+00 -4.72312E+00 * log10(te) + 1.58890E+00 * &
      &log10(te) ** 2 -2.69447E-01 * log10(te) ** 3 + &
      &1.58955E-02 * log10(te) ** 4
      AE5 = -5.15059E+00 -6.24549E+00 * log10(te) + 2.09801E+00 * &
      &log10(te) ** 2 -3.45649E-01 * log10(te) ** 3 + &
      &2.01962E-02 * log10(te) ** 4
      AE6 = -2.35923E+00 -8.75565E+00 * log10(te) + 2.95600E+00 * &
      &log10(te) ** 2 -4.77584E-01 * log10(te) ** 3 + &
      &2.78852E-02 * log10(te) ** 4
      AE7 =  1.55373E+00 -1.21894E+01 * log10(te) + 4.10096E+00 * &
      &log10(te) ** 2 -6.49318E-01 * log10(te) ** 3 + &
      &3.76487E-02 * log10(te) ** 4
      AE8 =  6.59883E+00 -1.64030E+01 * log10(te) + 5.43844E+00 * &
      &log10(te) ** 2 -8.40253E-01 * log10(te) ** 3 + &
      &4.79786E-02 * log10(te) ** 4

      if (log10(ne) .lt. 2) then
            aeff_hb = ae2
      elseif (log10(ne) .GE. 2 .AND. log10(ne) .LT. 3) then
            aeff_hb = AE2 + (AE3 - AE2) * (log10(ne) - 2)
      elseif (log10(ne) .GE. 3 .AND. log10(ne) .LT. 4) then
            aeff_hb = AE3 + (AE4 - AE3) * (log10(ne) - 3)
      elseif (log10(ne) .GE. 4 .AND. log10(ne) .LT. 5) then
            aeff_hb = AE4 + (AE5 - AE4) * (log10(ne) - 4)
      elseif (log10(ne) .GE. 5 .AND. log10(ne) .LT. 6) then
            aeff_hb = AE5 + (AE6 - AE5) * (log10(ne) - 5)
      elseif (log10(ne) .GE. 6 .AND. log10(ne) .LT. 7) then
            aeff_hb = AE6 + (AE7 - AE6) * (log10(ne) - 6)
      elseif (log10(ne) .GE. 7 .AND. log10(ne) .LT. 8) then
            aeff_hb = AE7 + (AE8 - AE7) * (log10(ne) - 7)
      else
            aeff_hb = AE8
      endif

      LogEm = aeff_hb - 11.38871 ! = log10(hc/lambda in cgs)
      aeff_hb = 10**aeff_hb
      em_hb = 10**logem

      end subroutine get_aeff_hb

      end module mod_recombination_lines
